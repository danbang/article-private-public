% Bang et al (2020) Private-public mappings in human prefrontal cortex
%
% Reproduces Figure 4-figure supplement 2
%
% "Private confidence" is computed by training multinomial regression on
% data from prescan session and then applying weights to data from fMRI
% session while setting context weights to zero
%
% Visualises private confidence under fitted model as a function of motion 
% coherence and choice reaction time
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
    
    % Visualise prediction
    coh_v= [1:4]-2.5;
    rt1_v= quantile(log(data.rt1),10);
    for i_coh= 1:length(coh_v);
        for i_rt1= 1:length(rt1_v);
            % Predictors
            X= [coh_v(i_coh); rt1_v(i_rt1); 0; 0; 0; 0;]';
            % Apply fitted weights
            Yhat= mnrval(betas{s},X,'model','ordinal','link','probit');
            % Save prediction (i.e. expectation under fitted weights)
            visualz(i_coh,i_rt1,s)= 7-sum(repmat([1:6],size(Yhat,1),1).*Yhat,2);
        end
    end
end

%% Plot visualisation
figure('color',[1 1 1]);
colz= [.75 .75 .75; .5 .5 .5; .25 .25 .25; 0 0 0];
group= mean(visualz,3);
for i_c= 1:4;
    plot(group(i_c,:),'-','Color',colz(i_c,:),'LineWidth',4); hold on;
end
set(gca,'FontSize',34,'LineWidth',4);
set(gca,'XTick',1:10);
set(gca,'YTick',2.5:.5:5.5)
xlabel('RT quantile','FontSize',44);
ylabel('private confidence','FontSize',44);
xlim([.5 10.5]);
ylim([2.2 4.8]);
box off;
print('-djpeg','-r300',['Figures',filesep,'Figure4_S2']);