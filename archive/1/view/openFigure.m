function figID = openFigure(n, figSize)
    figID = figure(n);
    % box off;
    set(gcf,'color','w');
    scnsize = get(0,'ScreenSize');
    position = get(figID,'Position');
    outerpos = get(figID,'OuterPosition');
    borders = outerpos - position;
    edge = -borders(1)/2;
    if strcmp(figSize,'full')
        pos1 = [0, 0, scnsize(3), scnsize(4)];
    else
        pos1 = [scnsize(3)/2 + edge, 0, scnsize(3)/2 - edge, scnsize(4)];
    end
    set(figID,'OuterPosition',pos1);