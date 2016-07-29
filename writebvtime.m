% write the bvtime string as recognized by parsebvtime
function str = writebvtime(dtObj)
	% UNBELIVEABLE... the format for datetime and datestr do not match... MM and mm change meaning. Also no SSSSSSS. must use FFF000
	str = datestr(dtObj, 'yyyymmddHHMMssFFF000');
	