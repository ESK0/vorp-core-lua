db = {}

local UPDATE_BAN = 'UPDATE users SET banned = ?, banneduntil = ? WHERE identifier = ?'
function db.updateBan(parameters)
    MySQL.prepare(UPDATE_BAN, parameters)
end

local SELECT_WARNINGS = 'SELECT `warnings` FROM `users` WHERE `identifier` = ?'
function db.selectWarnings(parameters)
    MySQL.prepare.await(SELECT_WARNINGS, parameters)
end

local UPDATE_WARNINGS = 'UPDATE `users` SET `warnings` = ? WHERE `identifier` = ?'
function db.updateWarnings(parameters)
    MySQL.prepare(UPDATE_WARNINGS, parameters)
end

local UPDATE_LASTLOGIN = 'UPDATE `characters` SET `LastLogin` = NOW() WHERE `charidentifier` = ?'
function db.updateLastLogin(parameters)
    MySQL.prepare(UPDATE_LASTLOGIN, parameters)
end

local INSERT_NEW_USER = 'INSERT INTO users VALUES(?, ?, ?, ?, ?, ?)'
function db.insertNewUser(parameters)
    MySQL.insert(INSERT_NEW_USER, parameters)
end