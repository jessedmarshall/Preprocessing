function [figHandle figAdd] = openFigure(figNo, figSize,varargin)
    % opens a figure, if default not set to docked, opens figure on the left half of the screen
    % biafra ahanonu
    % started: 2013.10.29
    % inputs
        %
    % outputs
        %
    % changelog
        %
    % TODO
        %

    %========================
    options.add = 1;
    % get options
    options = getOptions(options,varargin);
    % display(options)
    % unpack options into current workspace
    % fn=fieldnames(options);
    % for i=1:length(fn)
    %   eval([fn{i} '=options.' fn{i} ';']);
    % end
    %========================

    %
    if ishandle(figNo)
        set(0,'CurrentFigure',figNo)
        figHandle = figNo;
    else
        figHandle = figure(figNo);
    end
    % when making plots, have them be sequential
    figAdd = figNo+options.add;
    % box off;
    set(gcf,'color','w');

    if ~strcmp(get(0,'DefaultFigureWindowStyle'),'docked')
        scnsize = get(0,'ScreenSize');
        position = get(figHandle,'Position');
        outerpos = get(figHandle,'OuterPosition');
        borders = outerpos - position;
        edge = -borders(1)/2;
        if strcmp(figSize,'full')
            pos1 = [0, 0, scnsize(3), scnsize(4)];
        else
            pos1 = [scnsize(3)/2 + edge, 0, scnsize(3)/2 - edge, scnsize(4)];
        end
        set(figHandle,'OuterPosition',pos1);
    end