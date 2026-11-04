function hash = file_hash(file)
%FILE_HASH SHA-256 of exact file bytes (MATLAB JVM required).
fid = fopen(file,'rb');
if fid < 0, error('OceanScope:IO','Cannot read %s',file); end
cleanup = onCleanup(@() fclose(fid));
md = java.security.MessageDigest.getInstance('SHA-256');
while ~feof(fid)
    md.update(fread(fid,1048576,'*uint8'));
end
hash = lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
end
