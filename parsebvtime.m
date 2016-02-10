% parse the string returned by BrainVision New Segement marker (called bvtime) into a datetime object
function dtObj = parsebvtime(str)
	dtObj = datetime(str, 'InputFormat', 'yyyyMMddHHmmssSSSSSS');
	