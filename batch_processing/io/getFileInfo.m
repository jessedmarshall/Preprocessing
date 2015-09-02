function [fileInfo] = getFileInfo(fileStr, varargin)
	% gets file information for subject based on the file path, returns a structure with various information
	% biafra ahanonu
	% started: 2013.11.04 [12:38:42]
	% inputs
		% fileStr
	% options
		% assayList
	% outputs
		%

	% changelog
		%
	% TODO
		%

	%========================
	options.assayList = {...
	'MAG|PAV(|-PROBE)|(Q|)EXT|REN|REINST|S(HC|CH)|SUL(|P)|SAL|TROP|epmaze|OFT|HAL|D',...
	'|formalin|hcplate|vonfrey|acetone|pinprick|habit|preSNI|postSNI',...
	'|OFT|roto|oft|openfield|liquidOpenfield|check|groombox|socialcpp',...
	'|mag|reversalPre|reversalPost|reversalTraining|revTrain|reversalAcq|reversalRevOne|reversalRevTwo|reversalRevThree|reversalRevFour|reversalExtOne|reversalRenOne',...
	'|fear|SNIday|day|Session|mount|mountCheck|doubleCheck',...
	'|unc9975|unc|hal|ari'};
	% {'MAG|PAV(|-PROBE)|(Q|)EXT|REN|REINST|S(HC|CH)|SUL(|P)|SAL|TROP|epmaze|OFT|','formalin|hcplate|vonfrey|acetone|pinprick|habit|','OFT|roto|oft|openfield'};
	options.subjectRegexp = '(m|M|f|F|Mouse|mouse)\d+';
	options.originalStr = {'PAV-PROBE','SAL','SULP','SHC','REINST','EXT'};
	options.replaceStr = {'PAVQ','SCH','SUL','SCH','REN','EXT'};
	options.dateRegexp = '(\d{8}|\d{6}|\d+_\d+_\d+)';
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	% get the subject name/ID
	fileInfo.subject = regexp(fileStr,options.subjectRegexp, 'match');
	if ~isempty(fileInfo.subject)
		fileInfo.subject = lower(fileInfo.subject{1});
	else
		fileInfo.subject = 'm000';
	end
	% get subject number
	tmpMatch = regexp(fileInfo.subject,options.subjectRegexp, 'tokens');
	fileInfo.subjectNum = str2num(char(strrep(fileInfo.subject,tmpMatch{1},'')));

	% get protocol, if no protocol, send to graveyard of 000
	fileInfo.protocol = regexp(fileStr,'p\d+', 'match');
	if ~isempty(fileInfo.protocol)
		fileInfo.protocol = fileInfo.protocol{1};
	else
	    fileInfo.protocol = 'p000';
	end

	% get the assay used
	assayListOriginal = ['(' options.assayList{:} ')'];
	assayList = strcat(assayListOriginal, '\d+');
	fileInfo.assay = regexp(fileStr,assayList, 'match');
	% correct inconsistencies in naming

	for i=1:length(options.originalStr)
		fileInfo.assay = strrep(fileInfo.assay,options.originalStr{i},options.replaceStr{i});
	end
	% add NULL string if no assay found
	if ~isempty(fileInfo.assay)
		fileInfo.assay = fileInfo.assay{1};
	else
		fileInfo.assay = 'NULL000';
	end
	% % get out the assay name
	fileInfo.assayType = regexp(fileInfo.assay,'\D+','match');
	% strfind(fileInfo.assay,assayListOriginal)
	fileInfo.assayType = fileInfo.assayType{1,1};
	% % get out the assay number
	fileInfo.assayNum = str2num(cell2mat(regexp(fileInfo.assay,'\d+','match')));

	% date
	fileInfo.date = regexp(fileStr,options.dateRegexp, 'match');
	if ~isempty(fileInfo.date)
		fileInfo.date = fileInfo.date{1};
		% correct date inconsistency
		% length(fileInfo.date)
		if length(fileInfo.date)==6&~isempty(fileInfo.date)
			fileInfo.date = ['20' fileInfo.date(1:2) '_' fileInfo.date(3:4) '_' fileInfo.date(5:6)];
		elseif length(fileInfo.date)==8
			fileInfo.date = [fileInfo.date(1:4) '_' fileInfo.date(5:6) '_' fileInfo.date(7:8)];
		else
			% fileInfo.date = [fileInfo.date(1:4) '_' fileInfo.date(5:6) '_' fileInfo.date(7:8)];
		end
	else
		fileInfo.date = '0000_00_00';
	end