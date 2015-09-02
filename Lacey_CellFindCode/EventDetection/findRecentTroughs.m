function [vectowrite,vectoramplitudes] = findRecentTroughs(inputtraces,filteredtrace,peakpoints)

% Laurie Burns, Aug 2011.

diffval = [0 diff(filteredtrace)];
diffval2 = filteredtrace(3:end)-filteredtrace(1:end-2);
diffval2 = [0 0 diffval2];
diffval3 = filteredtrace(5:end)-filteredtrace(1:end-4);
diffval3 = [0 0 0 0 diffval3];
diffval = diffval>0;
diffval2 = diffval2>0;
diffval3 = diffval3>0;
vectowrite = zeros(1,0);
vectoramplitudes = zeros(1,0);
for tp = peakpoints
    t1 = max(1,tp-40); t2 = tp-2;
    testdiff = diffval(t2:-1:t1);
    testdiff2 = diffval2(t2:-1:t1);
    testdiff3 = diffval3(t2:-1:t1);
    T = find((testdiff==0 & testdiff2==0 & testdiff3==0),1,'first');
    if ~isempty(T)
        T = t2-T+1;
        % calculate the difference in DF value
        vectoramplitudes = [vectoramplitudes,inputtraces(tp) - inputtraces(T)];
    else T = t1;
        % if went to the max, just use the height
        vectoramplitudes = [vectoramplitudes,inputtraces(tp)];
    end
    vectowrite = [vectowrite,T];
end