-- DeltaOperations.lua
-- Delta computation and application logic for DeltaSync
-- Extracted and generalized from TOGBankClassic's DeltaComms module
-- 
-- This module handles:
-- - Computing deltas between two data states (array-based and structured)
-- - Applying deltas to current state
-- - Helper functions for indexing, comparison, and field extraction

-- No MINOR here: only the constant at DeltaSync.lua's NewLibrary call site is
-- the library revision LibStub compares. A second one in this file would be
-- unused at best and misleading at worst.
local MAJOR = "DeltaSync-1.0"
-- Silent lookup so the guard below is the thing that reports a bad TOC order.
-- Without `true`, LibStub raises its own generic "Cannot find a library instance"
-- first and this file's far more actionable message was unreachable.
local lib = LibStub:GetLibrary(MAJOR, true)

if not lib then
    -- error() never returns, so no `return` follows it: one did, and it was a
    -- permanently uncoverable line that read as a gap.
    error("DeltaOperations requires DeltaSync-1.0 to be loaded first")
end

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Build an index for fast lookups in an array of objects
-- @param array: array of objects to index
-- @param keyFunc: function to generate key from object (optional, uses obj itself as key)
-- @return: table mapping keys to objects
local function BuildIndex(array, keyFunc)
    local index = {}
    if not array then
        return index
    end
    
    for i, obj in ipairs(array) do
        if obj then
            local key = keyFunc and keyFunc(obj, i) or obj
            if key then
                index[key] = obj
            end
        end
    end
    
    return index
end

-- Report a keying hazard exactly once per host.
--
-- Both conditions this guards cause SILENT divergence — a permanent full resync,
-- or removals that never apply — so they have to be visible even when the host
-- has debug logging switched off. Once per host per condition keeps that from
-- becoming spam, since the condition recurs for every record in every diff.
function lib:_WarnKeying(id, message)
    self._keyingWarnings = self._keyingWarnings or {}
    if self._keyingWarnings[id] then return end
    self._keyingWarnings[id] = true
    self:Debug("DELTA", "VALIDATE", "%s", message)
    print("|cffff8800[DeltaSync]|r " .. message)
end

-- Resolve the key function for an array operation.
--
-- The built-in default falls back to tostring(obj) — a TABLE ADDRESS — for a
-- record carrying none of id/ID/key/name. Addresses are stable neither across
-- sessions nor between clients, so every record keys uniquely, every diff
-- reports everything added AND everything removed, and the consumer full-resyncs
-- forever with no error at all. Positional records (e.g. {id, count, suffix})
-- hit this immediately.
--
-- options.strictKeys turns it into an error; otherwise it warns once.
function lib:_ResolveKeyFunc(options)
    if options.keyFunc then return options.keyFunc end
    local host = self
    return function(obj, index)
        if type(obj) == "table" then
            if obj.id   then return tostring(obj.id)   end
            if obj.ID   then return tostring(obj.ID)   end
            if obj.key  then return tostring(obj.key)  end
            if obj.name then return tostring(obj.name) end
        end
        if options.strictKeys then
            error("DeltaSync: no stable key for a record — it has no id/ID/key/name field and " ..
                  "no options.keyFunc was supplied. Positional records must pass options.keyFunc.", 3)
        end
        host:_WarnKeying("address-key",
            "ComputeArrayDelta/ApplyArrayDelta fell back to a table ADDRESS as a record key, " ..
            "because the record has no id/ID/key/name field and no options.keyFunc was given. " ..
            "Addresses are not stable, so every sync will diff as all-added/all-removed and " ..
            "never converge. Pass options.keyFunc (or options.strictKeys to make this an error).")
        return tostring(obj)
    end
end

-- The default key function now lives in lib:_ResolveKeyFunc above, which wraps
-- the same id/ID/key/name lookup so the unstable address fallback can report
-- itself instead of silently causing a permanent full resync.

-- Deep comparison of two objects
-- @param obj1: first object
-- @param obj2: second object
-- @param ignoredFields: table of field names to ignore (optional)
-- @return: true if objects are equal, false otherwise
local function ObjectsEqual(obj1, obj2, ignoredFields, seen)
    if obj1 == obj2 then
        return true
    end

    if type(obj1) ~= type(obj2) then
        return false
    end

    if type(obj1) ~= "table" then
        return obj1 == obj2
    end

    ignoredFields = ignoredFields or {}

    -- Cycle guard. Without it a self-referential table recurses until the stack
    -- blows and the CLIENT HANGS — a far worse outcome than a wrong answer. A
    -- pair already under comparison is treated as equal: the enclosing
    -- comparison is the one that decides, and this only stops us re-walking it.
    seen = seen or {}
    local seenPair = seen[obj1]
    if seenPair then
        if seenPair[obj2] then return true end
    else
        seenPair = {}
        seen[obj1] = seenPair
    end
    seenPair[obj2] = true

    -- Compare all fields in obj1
    for k, v in pairs(obj1) do
        if not ignoredFields[k] then
            if type(v) == "table" then
                if not ObjectsEqual(v, obj2[k], ignoredFields, seen) then
                    return false
                end
            else
                if v ~= obj2[k] then
                    return false
                end
            end
        end
    end
    
    -- Check for fields present in obj2 but not in obj1
    for k in pairs(obj2) do
        if not ignoredFields[k] and obj1[k] == nil then
            return false
        end
    end
    
    return true
end

-- The reserved key on a `modified` entry that lists the fields DELETED from a
-- surviving record. Lua cannot store nil in a table, so "this field is gone"
-- needs an explicit spelling on the wire; without one a deletion was detected,
-- assigned as `changes[field] = nil`, and discarded by the assignment itself --
-- the receiver kept the stale field forever and both sides believed they were
-- in sync (AUDIT finding 7). ApplyArrayDelta strips it before mergeFunc runs, so
-- a custom merge never sees it. A record must not use this field name itself.
local REMOVED_FIELDS_KEY = "_removed"
lib.REMOVED_FIELDS_KEY = REMOVED_FIELDS_KEY

-- Get changed fields between two objects
-- @param oldObj: original object
-- @param newObj: updated object
-- @param keyFields: array of fields to always include for identification
-- @return: table containing only changed fields plus key fields, plus a
--          `_removed` list of field names present in oldObj and absent from
--          newObj (omitted when nothing was deleted)
local function GetChangedFields(oldObj, newObj, keyFields)
    local changes = {}

    -- Always include key fields for identification
    if keyFields then
        for _, field in ipairs(keyFields) do
            if newObj[field] ~= nil then
                changes[field] = newObj[field]
            end
        end
    end

    -- Find changed fields
    for field, newValue in pairs(newObj) do
        if oldObj[field] ~= newValue then
            if type(newValue) == "table" then
                -- Deep comparison for tables
                if not ObjectsEqual(oldObj[field], newValue) then
                    changes[field] = newValue
                end
            else
                changes[field] = newValue
            end
        end
    end

    -- Find DELETED fields: present on the old record, gone from the new one.
    -- The loop above walks newObj only, so it can never visit these.
    local removed
    for field in pairs(oldObj) do
        if newObj[field] == nil then
            removed = removed or {}
            table.insert(removed, field)
        end
    end
    if removed then
        table.sort(removed, function(a, b) return tostring(a) < tostring(b) end)
        changes[REMOVED_FIELDS_KEY] = removed
    end

    return changes
end

-- ============================================================================
-- ARRAY DELTA OPERATIONS
-- ============================================================================

-- Compute delta between two arrays of objects
-- @param oldArray: original array
-- @param newArray: updated array
-- @param options: table with optional fields:
--   - keyFunc: function(obj) to generate unique key for object. It MUST key
--     from the object's own fields only. A second `index` argument is passed
--     when the object sits in an array being scanned, and is NIL when the
--     object is a reduced delta entry (a `removed` or `modified` record on
--     apply) -- so a key derived from the index computes differently on the
--     two sides and removals silently never match. Positional identity is not
--     stable across clients in any case; see _ResolveKeyFunc.
--   - equalFunc: function(obj1, obj2) to compare objects for equality
--   - keyFields: array of fields to include in modified entries for identification
-- @return: delta table with added, modified, removed arrays. A `modified`
--   entry carries the changed fields plus keyFields, and -- when the sender
--   deleted fields from the record -- a `_removed` list of their names
--   (lib.REMOVED_FIELDS_KEY), which ApplyArrayDelta consumes.
function lib:ComputeArrayDelta(oldArray, newArray, options)
    local delta = {
        added = {},
        modified = {},
        removed = {}
    }
    
    oldArray = oldArray or {}
    newArray = newArray or {}
    options = options or {}
    
    local keyFunc = self:_ResolveKeyFunc(options)
    local equalFunc = options.equalFunc or ObjectsEqual
    local keyFields = options.keyFields or {}
    
    -- Build index for old array
    local oldByKey = BuildIndex(oldArray, keyFunc)
    
    -- Track which old entries have been matched (prevents duplicate matching)
    local matchedOld = {}

    -- Pre-pass: two records in newArray sharing a key describe the same identity
    -- twice. Left alone that emitted TWO entries for one target and, on apply,
    -- the second overwrote the first — so the surviving record depended on the
    -- order the host happened to build its array in. Deterministic for one
    -- client, but two clients whose source order differs (an array built from
    -- `pairs` over a map, say) then keep DIFFERENT records, hash differently,
    -- and offer each other data forever.
    --
    -- The library cannot know which duplicate is correct — that is a defect in
    -- the source data — so it reports once, keeps the LAST occurrence (exactly
    -- what apply already ended up doing) and emits ONE entry rather than two.
    -- `strictKeys` makes it an error, as with the other keying hazards.
    --
    -- Keys are computed once here and reused below, so this costs no extra
    -- keyFunc calls — only one table.
    local newKeys, lastIndexFor, duplicateKey = {}, {}, nil
    for i, newObj in ipairs(newArray) do
        if newObj then
            local k = keyFunc(newObj, i)
            newKeys[i] = k
            if lastIndexFor[k] ~= nil and duplicateKey == nil then
                duplicateKey = k
            end
            lastIndexFor[k] = i
        end
    end

    if duplicateKey ~= nil then
        if options.strictKeys then
            error(string.format(
                "DeltaSync: newArray holds more than one record keyed '%s'. Two records claiming " ..
                "the same identity is a source-data defect; the delta engine cannot know which is " ..
                "correct.", tostring(duplicateKey)), 3)
        end
        self:_WarnKeying("duplicate-key", string.format(
            "newArray holds more than one record keyed '%s'. Two records claiming the same " ..
            "identity is a source-data defect — the LAST one is kept, so two clients whose array " ..
            "order differs will keep different records and re-sync forever. De-duplicate before " ..
            "diffing, or pass options.strictKeys to make this an error.", tostring(duplicateKey)))
    end

    -- Find added and modified items
    for i, newObj in ipairs(newArray) do
        -- Skip a record superseded by a later one with the same key.
        if newObj and lastIndexFor[newKeys[i]] == i then
            local key = newKeys[i]
            local oldObj = oldByKey[key]

            if not oldObj then
                -- Object was added
                table.insert(delta.added, newObj)
                self:Debug("DELTA", "COMPUTE", "Added object: %s", tostring(key))
            elseif not equalFunc(oldObj, newObj) then
                -- Object was modified
                local changes = GetChangedFields(oldObj, newObj, keyFields)
                table.insert(delta.modified, changes)
                self:Debug("DELTA", "COMPUTE", "Modified object: %s", tostring(key))
            end

            -- Mark as processed
            matchedOld[key] = true
        end
    end
    
    -- Find removed items (anything in old but not matched in new)
    for key, oldObj in pairs(oldByKey) do
        if not matchedOld[key] then
            -- Extract key fields for identification in removal
            local removedEntry = {}
            if keyFields then
                for _, field in ipairs(keyFields) do
                    if oldObj[field] ~= nil then
                        removedEntry[field] = oldObj[field]
                    end
                end
            end
            -- If no key fields extracted, use the whole object
            if next(removedEntry) == nil then
                removedEntry = oldObj
            end

            -- INVARIANT: keyFields must cover every field keyFunc reads.
            --
            -- ApplyArrayDelta calls keyFunc on this REDUCED entry, so if the
            -- reduction drops a field the key depends on, the key computed on
            -- apply differs from the one computed here — the removal then
            -- matches nothing and the deleted item lingers forever, silently.
            -- (A keyFunc over (id, suffix) with keyFields = {"id"} is the
            -- classic case.) Comparing the two keys catches it for free.
            if removedEntry ~= oldObj then
                local ok, reducedKey = pcall(keyFunc, removedEntry)
                if not ok or reducedKey ~= key then
                    if options.strictKeys then
                        error(string.format(
                            "DeltaSync: options.keyFields does not cover every field options.keyFunc " ..
                            "reads. The removal entry keys as '%s' but the full record keys as '%s', " ..
                            "so this removal would never apply.", tostring(ok and reducedKey), tostring(key)), 3)
                    end
                    self:_WarnKeying("keyfields-coverage", string.format(
                        "options.keyFields does not cover every field options.keyFunc reads: a removal " ..
                        "reduced to keyFields keys as '%s' but the full record keys as '%s'. Removals " ..
                        "will silently never apply and deleted items will linger. Add the missing " ..
                        "field(s) to keyFields.", tostring(ok and reducedKey), tostring(key)))
                end
            end

            table.insert(delta.removed, removedEntry)
            self:Debug("DELTA", "COMPUTE", "Removed object: %s", tostring(key))
        end
    end
    
    self:Debug("DELTA", "COMPUTE", "Array delta: +%d ~%d -%d", 
        #delta.added, #delta.modified, #delta.removed)
    
    return delta
end

-- Apply array delta to current array
-- @param currentArray: array to modify (modified in place)
-- @param delta: delta table with added, modified, removed arrays
-- @param options: table with optional fields:
--   - keyFunc: function(obj) to generate unique key for object -- same
--     contract as ComputeArrayDelta: key from the object's fields only, never
--     from the optional index, which is nil for delta entries
--   - mergeFunc: function(existingObj, changes) to merge changes into existing
--     object. Never receives the `_removed` tombstone; deletions are applied
--     by the library after the merge returns.
-- @return: true if successful, false + error message if failed
function lib:ApplyArrayDelta(currentArray, delta, options)
    if not currentArray or not delta then
        return false, "Invalid array or delta"
    end
    
    options = options or {}
    local keyFunc = self:_ResolveKeyFunc(options)
    local mergeFunc = options.mergeFunc or function(existing, changes)
        for k, v in pairs(changes) do
            existing[k] = v
        end
    end
    
    -- Build index for current array
    local currentByKey = BuildIndex(currentArray, keyFunc)
    
    -- Process in order: removed → modified → added
    -- This prevents index issues when array is rebuilt
    
    -- STEP 1: Remove items
    if delta.removed then
        for _, removedObj in ipairs(delta.removed) do
            local key = keyFunc(removedObj)
            -- Find and remove from array
            for i = #currentArray, 1, -1 do
                local obj = currentArray[i]
                if obj and keyFunc(obj, i) == key then
                    table.remove(currentArray, i)
                    currentByKey[key] = nil
                    self:Debug("DELTA", "APPLY", "Removed object: %s", tostring(key))
                    break
                end
            end
        end
    end
    
    -- STEP 2: Modify existing items
    if delta.modified then
        for _, changes in ipairs(delta.modified) do
            -- Separate the deletion list from the field changes WITHOUT mutating
            -- the delta: the same delta may be applied to more than one target,
            -- and stripping the key in place would make the second apply lose
            -- its deletions. keyFunc and mergeFunc get a copy that never carries
            -- the library's own tombstone as a record field.
            local removedFields = changes[REMOVED_FIELDS_KEY]
            local fieldChanges = changes
            if removedFields ~= nil then
                fieldChanges = {}
                for k, v in pairs(changes) do
                    if k ~= REMOVED_FIELDS_KEY then fieldChanges[k] = v end
                end
            end

            local key = keyFunc(fieldChanges)
            local existingObj = currentByKey[key]

            if existingObj then
                -- Apply changes to existing object, then the deletions. Order
                -- matters only if a field is somehow in both lists; the deletion
                -- is the newer fact on the sender, so it wins.
                mergeFunc(existingObj, fieldChanges)
                if removedFields then
                    for _, field in ipairs(removedFields) do
                        existingObj[field] = nil
                    end
                end
                self:Debug("DELTA", "APPLY", "Modified object: %s (%d field(s) deleted)",
                    tostring(key), removedFields and #removedFields or 0)
            else
                -- Object doesn't exist (shouldn't happen), add as new. The
                -- deleted fields were never here, so there is nothing to remove.
                table.insert(currentArray, fieldChanges)
                currentByKey[key] = fieldChanges
                self:Debug("DELTA", "APPLY", "Modified object not found, added as new: %s",
                    tostring(key))
            end
        end
    end
    
    -- STEP 3: Add new items
    if delta.added then
        for _, newObj in ipairs(delta.added) do
            local key = keyFunc(newObj)
            local existingObj = currentByKey[key]
            
            if existingObj then
                -- Object already exists, update it (merge)
                mergeFunc(existingObj, newObj)
                self:Debug("DELTA", "APPLY", "Added object already exists, updated: %s", 
                    tostring(key))
            else
                -- Add new object
                table.insert(currentArray, newObj)
                currentByKey[key] = newObj
                self:Debug("DELTA", "APPLY", "Added new object: %s", tostring(key))
            end
        end
    end
    
    self:Debug("DELTA", "APPLY", "Applied array delta: array now has %d items", #currentArray)
    return true
end

-- ============================================================================
-- STRUCTURED DELTA OPERATIONS
-- ============================================================================

-- Compute delta between two structured data objects
-- @param oldData: original data structure
-- @param newData: updated data structure
-- @param metadata: optional metadata to include in delta (version, timestamp, etc.)
-- @param options: table with optional fields:
--   - arrayFields: table of field names that contain arrays (will use ComputeArrayDelta)
--   - scalarFields: table of field names that are scalar values (direct comparison)
--   - arrayOptions: table mapping array field names to options for ComputeArrayDelta
-- @return: delta structure with type="delta", a changes field, and -- only when
--   the sender deleted top-level fields -- a `removed` list of their names.
--   `changes[field] = nil` cannot exist in a Lua table, so a deletion needs
--   this explicit spelling or it is detected and then discarded (finding 7).
function lib:ComputeStructuredDelta(oldData, newData, metadata, options)
    if not newData then
        return nil, "newData is required"
    end

    oldData = oldData or {}
    metadata = metadata or {}
    options = options or {}

    local delta = {
        type = "delta",
        version = metadata.version or 0,
        timestamp = metadata.timestamp or 0,
        hash = metadata.hash or 0,
        changes = {}
    }
    local removed = {}

    -- Process scalar fields (direct value comparison)
    if options.scalarFields then
        for _, field in ipairs(options.scalarFields) do
            if newData[field] == nil and oldData[field] ~= nil then
                -- Deleted. Assigning nil into `changes` would create no key.
                table.insert(removed, field)
                self:Debug("DELTA", "COMPUTE", "Scalar field '%s' deleted (was %s)",
                    field, tostring(oldData[field]))
            elseif newData[field] ~= oldData[field] then
                delta.changes[field] = newData[field]
                self:Debug("DELTA", "COMPUTE", "Scalar field '%s' changed: %s → %s",
                    field, tostring(oldData[field]), tostring(newData[field]))
            end
        end
    end
    
    -- Process array fields (compute array deltas)
    if options.arrayFields then
        for _, field in ipairs(options.arrayFields) do
            local oldArray = oldData[field] or {}
            local newArray = newData[field] or {}
            local arrayOptions = options.arrayOptions and options.arrayOptions[field] or {}
            
            local arrayDelta = self:ComputeArrayDelta(oldArray, newArray, arrayOptions)
            
            -- Only include if there are changes
            if #arrayDelta.added > 0 or #arrayDelta.modified > 0 or #arrayDelta.removed > 0 then
                delta.changes[field] = arrayDelta
                self:Debug("DELTA", "COMPUTE", "Array field '%s' changed: +%d ~%d -%d",
                    field, #arrayDelta.added, #arrayDelta.modified, #arrayDelta.removed)
            end
        end
    end
    
    -- Process nested objects (recursive delta computation)
    for field, newValue in pairs(newData) do
        if type(newValue) == "table" and
           (not options.arrayFields or not self:TableContains(options.arrayFields, field)) and
           (not options.scalarFields or not self:TableContains(options.scalarFields, field)) then
            
            local oldValue = oldData[field]
            if not ObjectsEqual(oldValue, newValue) then
                delta.changes[field] = newValue
                self:Debug("DELTA", "COMPUTE", "Nested field '%s' changed", field)
            end
        end
    end

    -- Process DELETED nested objects: tables present on the old side and gone
    -- from the new. The loop above walks newData only, so it cannot see them.
    -- Scalar fields were handled above; array fields are diffed against an
    -- empty array (every record removed) by the arrayFields loop, so both are
    -- excluded here rather than tombstoned twice.
    for field, oldValue in pairs(oldData) do
        if type(oldValue) == "table" and newData[field] == nil and
           (not options.arrayFields or not self:TableContains(options.arrayFields, field)) and
           (not options.scalarFields or not self:TableContains(options.scalarFields, field)) then
            table.insert(removed, field)
            self:Debug("DELTA", "COMPUTE", "Nested field '%s' deleted", field)
        end
    end

    -- Deterministic order so two senders diffing the same change produce the
    -- same wire bytes; omitted entirely when empty so a delta with no deletions
    -- is byte-identical to one from a build without this field.
    if #removed > 0 then
        table.sort(removed, function(a, b) return tostring(a) < tostring(b) end)
        delta.removed = removed
    end

    self:Debug("DELTA", "COMPUTE", "Structured delta computed: %d field(s) changed, %d deleted",
        self:TableCount(delta.changes), #removed)

    return delta
end

-- Apply structured delta to current data
-- @param currentData: data structure to modify (modified in place)
-- @param delta: delta structure with changes field
-- @param options: table with optional fields:
--   - arrayFields: table of field names that contain arrays
--   - arrayOptions: table mapping array field names to options for ApplyArrayDelta
-- @return: true if successful, false + error message if failed
function lib:ApplyStructuredDelta(currentData, delta, options)
    if not currentData or not delta or not delta.changes then
        return false, "Invalid data or delta structure"
    end
    
    options = options or {}
    local success = true
    local errors = {}
    
    -- Apply changes
    for field, change in pairs(delta.changes) do
        -- Check if this is an array field
        local isArrayField = options.arrayFields and self:TableContains(options.arrayFields, field)
        
        if isArrayField and type(change) == "table" and (change.added or change.modified or change.removed) then
            -- This is an array delta, apply it
            if not currentData[field] then
                currentData[field] = {}
            end
            
            local arrayOptions = options.arrayOptions and options.arrayOptions[field] or {}
            local ok, err = self:ApplyArrayDelta(currentData[field], change, arrayOptions)
            
            if not ok then
                success = false
                table.insert(errors, string.format("Failed to apply delta to array field '%s': %s", 
                    field, err))
                self:Debug("DELTA", "APPLY", "ERROR: Failed to apply array delta to '%s': %s",
                    field, err)
            else
                self:Debug("DELTA", "APPLY", "Applied array delta to field '%s'", field)
            end
        else
            -- Scalar or nested object change, apply directly
            currentData[field] = change
            self:Debug("DELTA", "APPLY", "Applied change to field '%s'", field)
        end
    end

    -- Apply top-level deletions. Absent from a delta with none, and from any
    -- delta computed by a build before this field existed.
    if delta.removed then
        for _, field in ipairs(delta.removed) do
            currentData[field] = nil
            self:Debug("DELTA", "APPLY", "Deleted field '%s'", tostring(field))
        end
    end

    if not success then
        return false, table.concat(errors, "; ")
    end
    
    self:Debug("DELTA", "APPLY", "Structured delta applied successfully")
    return true
end

-- ============================================================================
-- DELTA VALIDATION
-- ============================================================================

-- Validate delta structure
-- @param delta: delta to validate
-- @return: true if valid, false + error message if invalid
function lib:ValidateDelta(delta)
    if not delta or type(delta) ~= "table" then
        return false, "delta is not a table"
    end
    
    if delta.type ~= "delta" then
        return false, "invalid delta type (expected 'delta')"
    end
    
    if not delta.changes or type(delta.changes) ~= "table" then
        return false, "missing or invalid changes field"
    end
    
    -- Validate version and timestamp if present
    if delta.version and type(delta.version) ~= "number" then
        return false, "invalid version (must be number)"
    end
    
    if delta.timestamp and type(delta.timestamp) ~= "number" then
        return false, "invalid timestamp (must be number)"
    end
    
    if delta.hash and type(delta.hash) ~= "number" then
        return false, "invalid hash (must be number)"
    end

    -- Top-level deletions, when present, are a list of field names.
    if delta.removed ~= nil then
        if type(delta.removed) ~= "table" then
            return false, "invalid removed list (must be a table of field names)"
        end
        for i, field in ipairs(delta.removed) do
            if type(field) ~= "string" and type(field) ~= "number" then
                return false, string.format("invalid removed field name at index %d", i)
            end
        end
    end

    -- Validate array deltas in changes
    for field, change in pairs(delta.changes) do
        if type(change) == "table" and (change.added or change.modified or change.removed) then
            -- This looks like an array delta, validate it
            if change.added and type(change.added) ~= "table" then
                return false, string.format("invalid added array in field '%s'", field)
            end
            if change.modified and type(change.modified) ~= "table" then
                return false, string.format("invalid modified array in field '%s'", field)
            end
            if change.removed and type(change.removed) ~= "table" then
                return false, string.format("invalid removed array in field '%s'", field)
            end
        end
    end
    
    return true
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Check if a table contains a value
-- @param tbl: table to search
-- @param value: value to find
-- @return: true if found, false otherwise
function lib:TableContains(tbl, value)
    if not tbl then
        return false
    end
    
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    
    return false
end

-- Count the number of entries in a table
-- @param tbl: table to count
-- @return: number of entries
function lib:TableCount(tbl)
    if not tbl then
        return 0
    end
    
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    
    return count
end

-- Get delta statistics
-- @param delta: delta structure to analyze
-- @return: table with statistics (added, modified, removed, totalChanges)
function lib:GetDeltaStats(delta)
    if not delta or not delta.changes then
        return {
            added = 0,
            modified = 0,
            removed = 0,
            totalChanges = 0,
            fields = 0
        }
    end
    
    local stats = {
        added = 0,
        modified = 0,
        removed = 0,
        totalChanges = 0,
        fields = 0
    }
    
    for _, change in pairs(delta.changes) do
        stats.fields = stats.fields + 1
        
        if type(change) == "table" then
            if change.added then
                stats.added = stats.added + #change.added
            end
            if change.modified then
                stats.modified = stats.modified + #change.modified
            end
            if change.removed then
                stats.removed = stats.removed + #change.removed
            end
        else
            stats.modified = stats.modified + 1
        end
    end

    -- Top-level field deletions count as removals and as touched fields, so a
    -- delta that carries nothing BUT deletions never reports zero changes.
    if delta.removed then
        stats.removed = stats.removed + #delta.removed
        stats.fields = stats.fields + #delta.removed
    end

    stats.totalChanges = stats.added + stats.modified + stats.removed
    
    return stats
end
