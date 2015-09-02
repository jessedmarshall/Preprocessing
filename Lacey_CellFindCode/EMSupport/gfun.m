function ydata = gfun(params, xdata)

% Written by Lacey Kitch in 2013

% xdata is two columns, first column is i (y) and seconds column is j (x)
% params is the parameters
% params = [mux, muy, sigx, sigy, theta, A]

% ydata comes out normalized so that the max is 1

mux=params(1);
muy=params(2);
sigx=params(3);
sigy=params(4);
theta=params(5);
A=params(6);

a=(cos(theta)^2)/(2*sigx^2)+(sin(theta)^2)/(2*sigy^2);
b=-sin(2*theta)/(4*sigx^2)+sin(2*theta)/(4*sigy^2);
c=(sin(theta)^2)/(2*sigx^2)+(cos(theta)^2)/(2*sigy^2);

ydata=zeros(size(xdata,1), 1);

for ind=1:size(xdata,1)
    i=xdata(ind,1);
    j=xdata(ind,2);
    
    ydata(ind)=A*exp(-(a*(j-mux).^2+...
        2*b*(j-mux)*(i-muy)+...
        c*(i-muy).^2));
end

% from file gfun on 12/11/13 at 6:00pm