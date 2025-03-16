clear
res=.001; % for cong greed.
% mconf=[2.4 3 4 4.6]; % mean of confidence vector
mconf=[2.3 3.1 3.9 4.7]; % mean of confidence vector
% this is the objective function to constrain the mean!
f= @(x,c)x.^(1:6)*(1:6)'/sum(x.^(1:6))-c;

%% find lower and uper bound bound for fzero....
% the issue is that f should be negative on the lower bound and positive on
% the upper bound.
fzero_low= 1e-2;
min_point_in_grid= 1+res; % minimal that is not one....
while f(fzero_low,min_point_in_grid)>0
    fzero_low=fzero_low/10;
end
% same logic for upper bound
fzero_high= 1e2;
max_point_in_grid= 6-res; 
while f(fzero_high,max_point_in_grid)<0
    fzero_high=fzero_high*10;
end

%%%%%%% END OF BORING fzero bound setting %%%%%%%%%%%%%

for kk=1: length(mconf)
    curr_mean= mconf(kk);
    if curr_mean==1
        max_entrop_conf_dist(kk,:)=[1 zeros(1,5)]; exitflag(kk)=1;
    elseif curr_mean==6
        max_entrop_conf_dist(kk,:)=[zeros(1,5) 1]; exitflag(kk)=1;
    else
        % maximal entropy confidence is a geometric series! which means
        % p{i}= a*x^i. The only qustion is x=?
        
        c= curr_mean;
        [y,fval(kk),exitflag(kk),output(kk)] = fzero(@(x)f(x,c), [fzero_low fzero_high]);
        max_entrop_conf_dist(kk,:)= y.^(1:6);
        max_entrop_conf_dist(kk,:)= max_entrop_conf_dist(kk,:)/sum(max_entrop_conf_dist(kk,:));
    end
    sanity(kk)= max_entrop_conf_dist(kk,:)*(1:6)';
end

% summary measures
maxent.cmean= sanity;
maxent.cdist= max_entrop_conf_dist;

save('maxent_cdist', 'maxent');