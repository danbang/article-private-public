% Bang et al (2020) Private-public mappings in human prefrontal cortex
%
% Reproduces Figure 3C
%
% Visualises ROI contrast estimates under GLM1 and performs associated 
% statistical test
%
% Note that contrast estimate for "signalled vs hidden" (SvH) context is not
% shown in Figure 3C but is included here
%
% Statistical tests can be reproduced by applying one-sample t-tests to
% contrast estimates: e.g. [H,P,CI,STATS]= ttest(beta{roi},0)
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
dataDir= [repoBase,fs,'Data',fs,'Behaviour',fs,'Scan'];
scanDir= [repoBase,fs,'Data',fs,'fMRI',fs,'ROI_ContrastEstimates'];

% Add customn functions
addpath('Functions');

% ROIs
my_ROIs= {'dACC','pgACC','FPl'};

%% -----------------------------------------------------------------------
%% VISUALISATION

% Loop through ROIs
for i_roi= 1:length(my_ROIs);
    % Specification
    figure('color',[1 1 1]);
    jitter=.5;
    ms= 14;
    dcol= [0 0 0];
    axisFS= 28;
    labelFS= 44;
    lw= 4;
    % statistics
    load([scanDir,fs,my_ROIs{i_roi},'_ContrastEstimates.mat']);
    my_data= contrastEstimates;
    beta{i_roi}= my_data;
    muz= mean(my_data);
    sem= std(my_data)/sqrt(n_subjects);
    % plot bars
    hold on;
    bar(muz,'FaceColor',[1 1 0],'FaceAlpha',.2,'LineWidth',lw); hold on;
    for i= 1:numel(muz); plot([i i],[muz(i)-sem(i) muz(i)+sem(i)],'k-','LineWidth',lw); end
    plot([0 length(muz)+1],[0 0],'k-','LineWidth',lw);
    % tidy up
    ylim([-0.7 1.7]); 
    set(gca,'YTick',-.5:.5:1.5);
    xlim([0 length(muz)+1]);
    set(gca,'Xtick',1:length(muz),'XTickLabel',{'K','K2','C','C2','SvH'});
    set(gca,'FontSize',axisFS,'LineWidth',4);
    xlabel('effect','FontSize',labelFS);
    ylabel('estimate','FontSize',labelFS);
    title(my_ROIs{i_roi},'FontSize',labelFS,'FontWeight','normal');
    box('off');
    axis square;
    print('-djpeg','-r300',['Figures',filesep,'Figure3C_',my_ROIs{i_roi}]);
end