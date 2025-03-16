% Bang et al (2020) Private-public mappings in human prefrontal cortex
%
% Reproduces Figure 1-figure supplement 3
%
% The visualisation is based on the analytical approach and code developed 
% by Rani Moran for "Bang et al. (2017). Confidence matching in group 
% decision-making. Nature Human Behaviour"
%
% The visualisation is based on an example subject (subject 1)
%
% Dan Bang danbang.db@gmail.com 2020

%% -----------------------------------------------------------------------
%% PREPARATION

% fresh memory
clear; close all;

% Paths [change 'repoBase' according to local setup]
fs= filesep;
repoBase= [getDropbox(1),fs,'Ego',fs,'Matlab',fs,'ucl',fs,'social_learn',fs,'Repository',fs,'GitHub'];
prescanBDir= [repoBase,fs,'Data',fs,'Behaviour',fs,'Prescan'];

% Add path to simulation sub-routines
addpath([repoBase,fs,'Landscape'])

%% -----------------------------------------------------------------------
%% RUN SIMULATION

% Load maximum entropy distributions
load('maxent_cdists.mat')
tmpdist= max_entrop_conf_dist; % confidence distribution
tmpdist_c(:,1)= [1:.1:6]; % mean associated with each distribution

% Load specifications for subject 1 obtained through calibration
load([prescanBDir,fs,'s1_stimulus.mat']);
my_noise= stimulus.noise; % fitted noise
my_stimuli= stimulus.coh; % selected levels of coherence - these have been hardcoded into calc_responses_by_gaussian.m
my_partners= [2.3 3.1 3.9 4.7]; % partner mean confidence
for i= 1:4; my_partners_index(i)= find(tmpdist_c==my_partners(i)); end; % partner index into confidence distributions

% Simulate landscape for expected accuracy
landscape_sim   = calc_landscape([my_noise my_noise],tmpdist,my_stimuli); 

%% -----------------------------------------------------------------------
%% VISUALISE SIMULATION

%% plot
figz=figure('color',[1 1 1]);
% landscape
colormap('parula');
imagesc(landscape_sim); hold on;
set(gca,'YDir','normal');
% overlay partners
for i= 1:4; 
    plot([my_partners_index(i) my_partners_index(i)],[0 my_partners_index(i)],'k-','LineWidth',2);
    plot([0 my_partners_index(i)],[my_partners_index(i) my_partners_index(i)],'k-','LineWidth',2);
end
plot([0 51],[0 51],'k-','LineWidth',4); hold on
set(gca,'LineWidth',4,'FontSize',32)
set(gca,'XTick',1:10:51,'YTick',1:10:51,'XTickLabel',{'1','2','3','4','5','6'},'YTickLabel',{'1','2','3','4','5','6'});
xlabel('partner(s) mean confidence','FontSize',32)
ylabel('subject mean confidence','FontSize',32)
c=colorbar;
set(c,'LineWidth',4);
set(c,'YTick',[.74 .82],'YTickLabel',{'min','max'});
caxis([.74 .82]);
axis square;
print(figz,'-djpeg','-r400',['Figures',filesep,'Figure1_S3']);    