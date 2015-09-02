function VRiD_color_plot(v1,v2,v3,colorbarOption)
    % biafra ahanonu
    % updated: 2013.06.18
    %Updated: 08/05/11
    %This file takes in at least two, single column vectors that are of equal
    %length (three for a 3D plot) and colour codes them according to their
    %position in the matrix, going from blue to black
    % 
    colors=hot(60);
    colour_sections=size(colors,1);
    bin_size=length(v1)/colour_sections; %Determines the step size for each colour
    if isempty(v3)==1
        for i=1:colour_sections
            if i==1
                xx=plot(v2(1:ceil(bin_size*i)),v1(1:ceil(bin_size*i)));
            else
                xx=plot(v2(ceil(bin_size*i-bin_size):ceil(bin_size*i)),v1(ceil(bin_size*i-bin_size):ceil(bin_size*i)));
            end
            set(xx,'Color',colors(i,:),'LineWidth',.5);
            if i==1
                hold on
            end
        end
    end
    if isempty(v3)==0
        for i=1:colour_sections
        if i==1
            xx=plot3(v2(1:ceil(bin_size*i)),v1(1:ceil(bin_size*i)),v1(1:ceil(bin_size*i)));
        else
            xx=plot3(v2(ceil(bin_size*i-bin_size):ceil(bin_size*i)),v1(ceil(bin_size*i-bin_size):ceil(bin_size*i)),v3(ceil(bin_size*i-bin_size):ceil(bin_size*i)));
        end
        set(xx,'Color',colors{i},'LineWidth',.5);
        if i==1
            hold on
        end
        end
    end
    if colorbarOption==1
        % set colormap to use for colorbar
        colormap(colors);
        colorbar;
    else
end