function [xOut, f] = photobleachCorrect(data,VOI,subtractedBG)
x = varfun(@nanmean, data,'InputVariables',VOI,'GroupingVariables','Time');
t = x{:,1};
x = x{:,3};

options = fitoptions('exp2');

if subtractedBG==0
    options.Lower = [-Inf -Inf -Inf 0];
    options.Upper = [Inf Inf Inf 0];
elseif subtractedBG==1
    options.Lower = [-Inf -Inf 0 0];
    options.Upper = [Inf Inf 0 0];
end

f = fit(t,x,'exp2',options);
xOut = (x - f.c)./exp(f.b.*t);

