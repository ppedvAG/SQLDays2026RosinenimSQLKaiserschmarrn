SELECT @@VERSION AS VersionInfo;
SELECT SERVERPROPERTY('ProductVersion') ProductVersion,
       SERVERPROPERTY('ProductLevel') ProductLevel,
       SERVERPROPERTY('Edition') Edition;
SELECT name,compatibility_level FROM sys.databases ORDER BY name;
