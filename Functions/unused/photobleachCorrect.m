function [xOut, f] = photobleachCorrect(data,VOI,subtractedBG,initial_conditions)
x = varfun(@nanmean, data,'InputVariables',VOI,'GroupingVariables','Frame');
t = x{:,1};
x = x{:,3};

options = fitoptions('exp2');
options.StartPoint = initial_conditions


if subtractedBG==0
    options.Lower = [-Inf -Inf -Inf 0];
    options.Upper = [Inf Inf Inf 0];
elseif subtractedBG==1
    options.Lower = [-Inf -Inf 0 0];
    options.Upper = [Inf Inf 0 0];
end

% disp('aaa')
f = fit(t,x,'exp2',options);

plot(t,x,'k.'); hold on;
plot(f)

% xOut = (x - f.c)./exp(f.b.*t);
xOut = (data.(VOI) - f.c)./exp(f.b.*(data.Frame-1));
