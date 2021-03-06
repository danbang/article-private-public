% Bang et al (2020) Private-public mappings in human prefrontal cortex
%
% Reproduces Figure 5
%
% "Private confidence" is computed by training multinomial regression on
% data from prescan session and then applying weights to data from fMRI
% session while setting context weights to zero
%
% Visualises functional coupling between FPl and pgACC/dACC as a function 
% of private confidence, public confidence and their interaction and
% performs associated statistical tests
%
% Dan Bang danbang.db@gmail.com 2020

%% -----------------------------------------------------------------------
%% PREPARATION

% fresh memory
clear; close all;

% Subjects
n_subjects= 28;

% Paths [change 'repoBase' according to local setup]
fs= filesep;
repoBase= [getDropbox(1),fs,'Ego',fs,'Matlab',fs,'ucl',fs,'social_learn',fs,'Repository',fs,'GitHub'];
prescanBDir= [repoBase,fs,'Data',fs,'Behaviour',fs,'Prescan'];
scanBDir= [repoBase,fs,'Data',fs,'Behaviour',fs,'Scan'];
scanFDir= [repoBase,fs,'Data',fs,'fMRI',fs,'ROI_TimeSeries'];

% Add customn functions
addpath('Functions');

% ROIs
my_ROIs= {'dACC','pgACC','FPl'};

%% -----------------------------------------------------------------------
%% COMPUTE PRIVATE CONFIDENCE

% Loop through subjects
for s= 1:n_subjects;
    
    % Load stimulus and context specifications
    load([prescanBDir,fs,'s',num2str(s),'_stimulus.mat']);
    load([prescanBDir,fs,'s',num2str(s),'_context.mat']);
    
    %% FIRST FIT MODEL USING PRESCAN DATA PHASE 3 (SAME SETUP AS IN FMRI)

    % Load file
    load([prescanBDir,fs,'s',num2str(s),'_social3.mat']);    

    % Translate miliseconds to seconds
    data.rt1= data.rt1/1000;
    data.rt2= data.rt2/1000;

    % Link confidence profile to partner identity
    context_v= context.con; % profile for partners 1-4;
    if length(task.settings.advo)>4; context_v(5)= 5; end % if hidden partner
    for t= 1:length(data.trial);
        data.context(t)= context_v(data.advcat(t));
    end
  
    % Fit multinomial regression
    % Load variables
    confidence= data.con;
    coherence= data.cohcat-2.5;
    reactiontime= log(data.rt1);
    context1= data.context==1;
    context2= data.context==2;
    context3= data.context==3;
    context4= data.context==4;
    context5= data.context==5;
    % Predictors
    X= [coherence; reactiontime; ...
        context1; context2; context3; context4]';
    % Outcome
    Y= 7-confidence;
    % Fit and save predictor weights
    [B,~,STATS] = mnrfit(X,Y,'model','ordinal','link','probit');
    betas{s}= B;
        
    %% THEN USE FITTED MODEL TO DERIVE ESTIMATES FOR SCAN DATA

    % Collate data from scan runs
    for i_r= 1:4;       
        % Load file
        load([scanBDir,fs,'s',num2str(s),'_social_run',num2str(i_r),'.mat']);    
        % Get data field names
        fn = fieldnames(data);
        % If first block, then initialise temporary storage structure
        if i_r == 1; 
            for i_field = 1:length(fn); 
                eval(['tmp.',fn{i_field},'=[];']); 
            end; 
        end
        % Add data to temporary storage structure
        for i_field = 1:length(fn)
            eval(['tmp.',fn{i_field},'=[tmp.',fn{i_field},' data.',fn{i_field},'];']);
        end               
    end
    
    % Rename collated data
    data=tmp;
            
    % Translate miliseconds to seconds
    data.rt1= data.rt1/1000;
    data.rt2= data.rt2/1000;

    % Link confidence profile to partner identity
    context_v= context.con; % profile for partners 1-4;
    if length(task.settings.advo)>4; context_v(5)= 5; end % if hidden partner
    for t= 1:length(data.trial);
        data.context(t)= context_v(data.advcat(t));
    end
    
    % Apply multinomial regression    
    % Load variables
    confidence= data.con;
    coherence= data.cohcat-2.5;
    reactiontime= log(data.rt1);
    context1= data.context==1;
    context2= data.context==2;
    context3= data.context==3;
    context4= data.context==4;
    context5= data.context==5;
    % Predictors
    X= [coherence; reactiontime; ...
        context1*0; context2*0; context3*0; context4*0;]';
    % Apply fitted weights
    Yhat= mnrval(betas{s},X,'model','ordinal','link','logit');
    % Save prediction (i.e. expectation under fitted weights)
    model.private{s}= 7-sum(repmat([1:6],size(Yhat,1),1).*Yhat,2);
     
end

%% -----------------------------------------------------------------------
%% QUANTIFY ROI FUNCTIONAL COUPLING

% Loop through subjects
for s= 1:n_subjects;

    % Load ROI data
    load([scanFDir,fs,'s',num2str(s),'_dACC_','TimeSeries.mat']);    
    dACC_ts = timeSeries;
    load([scanFDir,fs,'s',num2str(s),'_pgACC_','TimeSeries.mat']);    
    pgACC_ts = timeSeries;
    load([scanFDir,fs,'s',num2str(s),'_FPl_','TimeSeries.mat']);    
    FPl_ts = timeSeries;

    % Load stimulus and context specifications
    load([prescanBDir,fs,'s',num2str(s),'_stimulus.mat']);
    load([prescanBDir,fs,'s',num2str(s),'_context.mat']);

    % Collate data from scan runs
    for i_r= 1:4;       
        % Load file
        load([scanBDir,fs,'s',num2str(s),'_social_run',num2str(i_r),'.mat']);    
        % Get data field names
        fn = fieldnames(data);
        % If first block, then initialise temporary storage structure
        if i_r == 1; 
            for i_field = 1:length(fn); 
                eval(['tmp.',fn{i_field},'=[];']); 
            end; 
        end
        % Add data to temporary storage structure
        for i_field = 1:length(fn)
            eval(['tmp.',fn{i_field},'=[tmp.',fn{i_field},' data.',fn{i_field},'];']);
        end               
    end

    % Rename collated data
    data=tmp;

    % Translate miliseconds to seconds
    data.rt1= data.rt1/1000;
    data.rt2= data.rt2/1000;

    % Link confidence profile to partner identity
    context_v= context.con; % profile for partners 1-4;
    if length(task.settings.advo)>4; context_v(5)= 5; end % if hidden partner
    for t= 1:length(data.trial);
        data.context(t)= context_v(data.advcat(t));
    end

    % Include trials based on deviation from grand mean
    rt1= log(data.rt1./1000);
    centre= mean(rt1);
    stdval= std(rt1)*2.5;
    include= (rt1>(centre-stdval))&(rt1<(centre+stdval));
    
    % Include trials where final time-point estimate is ~NaN
    for i= 1:size(FPl_ts,1); if isnan(FPl_ts(i,end)); include(i)=0; end; end;

    % Include explicit trials
    for i= 1:length(data.context); if data.context(i)==5; include(i)=0; end; end;
    
    % UP-SAMPLED GLM
    dACC_Zts = zscore(dACC_ts(include,:));
    pgACC_Zts = zscore(pgACC_ts(include,:));
    FPl_Zts = zscore(FPl_ts(include,:));
    private= zscore(model.private{s}(include))';
    public= zscore(data.con(include));
    deviation= private-public;
    psy1= private;
    psy2= public;
    psy3= private.*public;
    t= 0;
    for j= 1:size(FPl_Zts,2)
        t= t+1;
        % dACC
        x= [psy1; psy2; psy3; FPl_Zts(:,j)'; FPl_Zts(:,j)'.*psy1; FPl_Zts(:,j)'.*psy2; FPl_Zts(:,j)'.*psy3]';
        y= dACC_Zts(:,j);
        beta= glmfit(x,y,'normal');
        beta_ts_PPI1{1}(s,t)= beta(end-2);
        beta_ts_PPI2{1}(s,t)= beta(end-1);
        beta_ts_PPI3{1}(s,t)= beta(end-0);
        % pgACC
        x= [psy1; psy2; psy3; FPl_Zts(:,j)'; FPl_Zts(:,j)'.*psy1; FPl_Zts(:,j)'.*psy2; FPl_Zts(:,j)'.*psy3]';
        y= pgACC_Zts(:,j);
        beta= glmfit(x,y,'normal');
        beta_ts_PPI1{2}(s,t)= beta(end-2);
        beta_ts_PPI2{2}(s,t)= beta(end-1);
        beta_ts_PPI3{2}(s,t)= beta(end-0);
    end
    
end

%% -----------------------------------------------------------------------
%% VISUALISE ROI FUNCTIONAL COUPLING

%% FIGURE 5A
my_PPI= {'FPl-dACC','FPl-pgACC'};
% specifications
max_t = 85;
srate = .144;
lw=4;
ms= 8;
axisFS= 34;
labelFS= 44;
% Loop through ROIs
for i_PPI= 1:length(my_PPI);
figure('color',[1 1 1]);
plot([0 max_t+20],[0 0],'k-','LineWidth',lw); hold on
plot([2/srate 2/srate],[-1 +1],'k--','LineWidth',lw/2); hold on
PPI= beta_ts_PPI1{i_PPI};
PPIP= ttest(PPI,0);
for t= 1:length(PPIP); if PPIP(t)==1; plot(t,-.055,'s','color','m','MarkerFaceColor','m','MarkerSize',ms); end; end;
fillsteplotm(PPI,lw);
PPI= beta_ts_PPI2{i_PPI};
PPIP= ttest(PPI,0);
for t= 1:length(PPIP); if PPIP(t)==1; plot(t,-.06,'s','color','c','MarkerFaceColor','c','MarkerSize',ms); end; end;
fillsteplotc(PPI,lw);
PPI= beta_ts_PPI3{i_PPI};
PPIP= ttest(PPI,0);
for t= 1:length(PPIP); if PPIP(t)==1; plot(t,-.065,'s','color','g','MarkerFaceColor','g','MarkerSize',ms); end; end;
fillsteplotg(PPI,lw);
ylim([-.07 .07]); 
xlim([0 max_t]);
xlabel('time [seconds]','FontSize',labelFS,'FontWeight','normal');
ylabel('beta [a.u.]','FontSize',labelFS,'FontWeight','normal');
set(gca,'YTick',[-.06:.02:.06]);
set(gca,'XTick',0:14:max_t-2)
set(gca,'XTickLabel',{'-2','0','2','4','6','8'})
box('off')
set(gca,'FontSize',axisFS,'LineWidth',lw);
title(my_PPI{i_PPI},'FontSize',labelFS,'FontWeight','normal');
axis square;
print('-djpeg','-r300',['Figures',filesep,'Figure5A_',my_PPI{i_PPI}]);
end

%% -----------------------------------------------------------------------
%% VISUALISE FPl-dACC COUPLING PROFILE

% Compute average coefficients for the window 6-8s after onset of context screen 
B_private= mean(mean(beta_ts_PPI1{1}(:,round(8/srate):round(10/srate))));
B_public= mean(mean(beta_ts_PPI2{1}(:,round(8/srate):round(10/srate))));
B_interaction= mean(mean(beta_ts_PPI3{1}(:,round(8/srate):round(10/srate))));
% Prepare vector for varying variables in z-score units
SD_v= -3:.5:3;
% Estimate connectivity under variation in variables
clear PPI
for i_public= 1:length(SD_v);
    for i_private= 1:length(SD_v);
        PPI(i_public,i_private)= B_private*SD_v(i_private) + B_public*SD_v(i_public) + B_interaction*SD_v(i_private)*SD_v(i_public);
    end
end
% Plot estimated connectivity
figure('color',[1 1 1]);
imagesc(PPI); hold on;
plot([0 14],[0 14],'k-','LineWidth',lw);
set(gca,'YDir','normal');
c=colorbar;
caxis([-.5 .5]);
xlabel('private confidence','FontSize',labelFS);
ylabel('public confidence','FontSize',labelFS);
set(gca,'LineWidth',lw,'FontSize',axisFS);
set(c,'LineWidth',lw);
set(gca,'XTick',[1 length(SD_v)],'XTickLabel',{'min','max'});
set(gca,'YTick',[1 length(SD_v)],'YTickLabel',{'min','max'});
set(c,'YTick',[-.5 .5],'YTickLabel',{'min','max'});
title('FPl-dACC','FontSize',labelFS,'FontWeight','normal');
axis square;
print('-djpeg','-r300',['Figures',filesep,'Figure5B']);