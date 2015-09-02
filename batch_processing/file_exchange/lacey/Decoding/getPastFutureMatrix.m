function [Aout,Yout]=getPastFutureMatrix(A, Y, pf)

% Written by Lacey Kitch in 2012-2014

Aout=A;
Yout=Y;
for k=1:pf
   Aout=[[zeros(min(k,length(Y)),size(A,2)); A(1:end-k,:)], Aout];
end