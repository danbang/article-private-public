% Bang et al (2020) Private-public mappings in human prefrontal cortex
%
% Reproduces Figure 4-figure supplement 1
%
% "Private confidence" is computed by training multinomial regression on
% data from prescan session and then applying weights to data from fMRI
% session while setting context weights to zero
%
% Visualises cross-validation accuracy within date used to fit the
% confidence model (phase 3 in behavioural session)
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

% -----------------------------------------------------------------------
% CROSS-VALIDATION

% Loop through subjects
for s= 1:n_subjects;
    
    %% Customer service
    fprintf(['Cross-validating: subject ',num2str(s),' out of ',num2str(n_subjects),'\n']);
    
    %% Load stimulus and context specifications
    load([prescanBDir,fs,'s',num2str(s),'_stimulus.mat']);
    load([prescanBDir,fs,'s',num2str(s),'_context.mat']);
    
    %% Load behavioural data

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
    
    % Save data
    Bdata= data;
    
    %% Load fMRI data
    
    % Collate data from scan runs
    tmp= [];
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
    
    % Save data
    Fdata= data;
    
    %% Cross-validation: within behavioural session
        
    % Re-assign data
    data= Bdata;
    
    % Create trial indices
    trial_v= 1:length(data.trial);
    
    % Loop through trials
    for i_trial= trial_v;
        
        % Divide trial indices
        train_trial= trial_v(trial_v~=i_trial);
        test_trial= trial_v(trial_v==i_trial);
        
        % Fit multinomial regression
        % Specify variables
        confidence= data.con(train_trial);
        coherence= data.cohcat(train_trial)-2.5;
        reactiontime= log(data.rt1(train_trial));
        context1= data.context(train_trial)==1;
        context2= data.context(train_trial)==2;
        context3= data.context(train_trial)==3;
        context4= data.context(train_trial)==4;
        context5= data.context(train_trial)==5;
        % Predictor matrix
        X= [coherence; reactiontime; context1; context2; context3; context4]';
        % Outcome variable
        Y= 7-confidence;
        % Evaluate model
        B = mnrfit(X,Y,'model','ordinal','link','probit');
        
        % Cross-validate multinomial regression
        % Specify variables
        confidence= data.con(test_trial);
        coherence= data.cohcat(test_trial)-2.5;
        reactiontime= log(data.rt1(test_trial));
        context1= data.context(test_trial)==1;
        context2= data.context(test_trial)==2;
        context3= data.context(test_trial)==3;
        context4= data.context(test_trial)==4;
        context5= data.context(test_trial)==5;
        % Predictor matrix
        X= [coherence; reactiontime; context1; context2; context3; context4]';
        % Outcome variable
        Y= 7-confidence;
        % Evaluate model
        Ymodel= mnrval(B,X,'model','ordinal','link','probit');
        Ynull= ones(size(Y,1),6)./6;
        % Padding if response option not used
        unique_Y= unique(data.con(train_trial));
        if length(unique_Y)< 6;
            if unique_Y(1)==2 || unique_Y(end)==5;
                tmp= zeros(size(Y,1),6);
                tmp(:,unique_Y)= Ymodel;
                Ymodel= tmp;
            end
        end
        % Avoid zero probability
        zeroPadd= .01;
        Ymodel= (Ymodel+zeroPadd)./sum(Ymodel+zeroPadd);
        % Vectorise outcome variable
        Yvec= zeros(size(Y,1),6);
        for t=1:size(Yvec,1); Yvec(t,Y(t))=1; end
        % Compute log likelihoods
        LLmodel= sum(log(mnpdf(Yvec,Ymodel)));
        LLnull= sum(log(mnpdf(Yvec,Ynull)));
        crossvalLL{s}(i_trial,:)= [LLnull LLmodel];
    end
         
end

%% Plot cross-validation
figure('color',[1 1 1]);
for s= 1:n_subjects; crossvalDelta(s)= (-sum(crossvalLL{s}(:,1)))-(-sum(crossvalLL{s}(:,2))); end
bar(sort(crossvalDelta,'ascend'),'Facecolor','m','Edgecolor','w','FaceAlpha',.4); hold on;
plot([0 n_subjects+1],[0 0],'k-','LineWidth',4);
set(gca,'FontSize',34,'LineWidth',4);
set(gca,'XTick',[]);
set(gca,'YTick',0:25:200);
xlabel('subject','FontSize',44);
ylabel('-LL model-null','FontSize',44);
% title('cross-validation','FontSize',24,'FontWeight','normal');
box off;
print('-djpeg','-r300',['Figures',filesep,'Figure4_S1']);