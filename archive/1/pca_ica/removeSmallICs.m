function [IcaFilters, IcaTraces, valid] = removeSmallICs(IcaFilters, IcaTraces, varargin)
        % biafra ahanonu
        % 2013.10.31
        % based on SpikeE code
        %
        % Removes small and very large ICs
        %
        % changelog
            % updated: 2013.11.08 [09:24:12] removeSmallICs now calls a filterICs, name-change due to alteration in function, can slowly replace in codes

        [IcaFilters, IcaTraces, valid] = filterICs(IcaFilters, IcaTraces, varargin);