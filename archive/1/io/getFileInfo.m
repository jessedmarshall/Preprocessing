function [fileInfo] = getFileInfo(fileStr, varargin)
	% biafra ahanonu
	% updated: 2013.11.04 [12:38:42]
	% gets file information for mouse miniscope trials and returns as a

	% get the mouse
	fileInfo.mouse = regexp(fileStr,'(m|M|f|F)\d+', 'match');
	if ~isempty(fileInfo.mouse)
		fileInfo.mouse = fileInfo.mouse{1};
	else
		fileInfo.mouse = 'm000';
	end

	% get protocol, if no protocol, send to graveyard of 000
	fileInfo.protocol = regexp(fileStr,'p\d+', 'match');
	if ~isempty(fileInfo.protocol)
		fileInfo.protocol = fileInfo.protocol{1};
	else
	    fileInfo.protocol = 'p000';
	end

	% get the assay used
	pavList = 'MAG|PAV(|-PROBE)|(Q|)EXT|REN|REINST|S(HC|CH)|SUL(|P)|SAL|TROP|epmaze|OFT';
	painList = 'formalin|hcplate|vonfrey';
	hdList = 'OFT|roto';
	assayList = ['(' pavList '|' painList '|' hdList ')'];
	assayList = strcat(assayList, '\d+');
	fileInfo.assay = regexp(fileStr,assayList, 'match');
	% correct inconsistencies in naming
	originalStr = {'PAV-PROBE','SAL','SULP','SHC','REINST','EXT'};
	replaceStr = {'PAVQ','SCH','SUL','SCH','REN','QEXT'};
	for i=1:length(originalStr)
		fileInfo.assay = strrep(fileInfo.assay,originalStr{i},replaceStr{i});
	end
	% % get out the assay name
	% regexp(fileInfo.assay,'\D+','match')
	% % get out the assay number
	% regexp(fileInfo.assay,'\d+','match')
	if ~isempty(fileInfo.assay)
		fileInfo.assay = fileInfo.assay{1};
	else
		fileInfo.assay = 'NULL000';
	end

	% date
	fileInfo.date = regexp(fileStr,'(\d{6}|\d+_\d+_\d+)', 'match');
	if ~isempty(fileInfo.date)
		fileInfo.date = fileInfo.date{1};
		% correct date inconsistency
		if(length(fileInfo.date)<=6&~isempty(fileInfo.date))
			fileInfo.date = ['20' fileInfo.date(1:2) '_' fileInfo.date(3:4) '_' fileInfo.date(5:6)];
		end
	else
		fileInfo.date = '0000_00_00';
	end