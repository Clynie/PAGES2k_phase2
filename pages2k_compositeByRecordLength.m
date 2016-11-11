
% Purpose: investigate how the composite changes with start date
% Contributed by: Julien Emile-Geay, 12-Jun-2016

tMin = tEnd-[250 500 1000 1999];
yearMinQ = yearMin(idx_q);
cols = brewermap(length(tMin),'Dark2');
% bin parameters
binStep = 50;
binEdges=flipud((2000:-binStep:0)');
binYear=mean([binEdges(2:end) binEdges(1:end-1)],2);
plotEdges=reshape([binEdges(1:end-1) binEdges(2:end)]',[],1);
tb = binEdges(2:end);
% analysis parameters
n_tresh = 10; nboot = 500; % # of bootstrap samples.
% plotting parameters
style_l = style_t; style_l{4} = 12;  xlims = [0 2000];  K = 1.1; % expansion factor for tick marks

ylims       = [-0.75 1]; dy = 0.25;
yticks      = ylims(1):dy:ylims(2);  % define tick marks

fig('Sensitivity to record length'), clf
set(gcf,'Position',[440   270   852   628])
pmax = 300; % scale for # proxies
ylims = [-1 1]; thresh = 10;
hold on
for c = 1:4
    ax1 = subplot(2,2,c); col = cols(c,:);
    proxy_qb = bin_x(tce',proxy_q(:,yearMinQ<=tMin(c)),binEdges);
    pcom      = nmean(proxy_qb,2);
    p_boot    = bootstrp(nboot,@nmean,proxy_qb');
    ci_arch   = quantile(p_boot',[0.025 0.975],2);
    p_arch(c) = size(proxy_qb,2);    
    n_arch    = sum(~isnan(proxy_qb),2); 
    
    n_archPlot = reshape([n_arch n_arch]',[],1);
    pcom_archPlot = reshape([pcom pcom]',[],1);
    ciLo        = reshape([ci_arch(:,1) ci_arch(:,1)]',[],1);
    ciHi        = reshape([ci_arch(:,2) ci_arch(:,2)]',[],1);
    
    % plotting threshold
    thresh = (n_archPlot  >= n_tresh);
    % plot solid line otherwise, and number of proxies
    [ax,h1,h2]  = plotyy(tb,n_arch,plotEdges,pcom_archPlot,@bar,@line); hold on
    set(h1,'facecolor',rgb('Gainsboro'),'edgecolor','none')
    set(ax(1),'Ycolor',rgb('Silver'),'YAxisLocation','right');
    set(ax(1),'yLim',[0 600],'ytick',[0:100:600]);
    set(get(ax(1),'Ylabel'),'String','# records'), 
    set(get(ax(1),'Ylabel'),style_l{:}), set(ax(2),'yLim',ylims)
    %set(h2,'visible','off'); %make invisible for now;
    set(h2,'color',col,'linewidth',2,'linestyle',':');
    set(ax(2),'Ycolor',col,'YAxisLocation','left','Ytick',yticks)
    set(get(ax(2),'Ylabel'),'String','Composite');
    set(get(ax(2),'Ylabel'),style_l{:})
    set(gcf,'CurrentAxes',ax(2))
    set(ax(1),'Box', 'off', 'TickDir','out','TickLength',[.02 .02])
    set(ax(2),'Box', 'off', 'TickDir','out','TickLength',[.02 .02])
    
    % plot bootstrap CI
    wide = (~isnan(ciLo) & ciHi-ciLo>range(ylims)/50.0);  %
    hci = area_fill(plotEdges(wide)',ciLo(wide)',ciHi(wide)',col,col,0.2);
    %plot transparent line for entire period
    hp = line(plotEdges(thresh),pcom_archPlot(thresh),'color',col,'linewidth',2,'linestyle','-','Parent',ax(2));
    % plot solid line when enough data are present
    uistack(h2,'top')
    % more cosmetics
    linkaxes([ax(1),ax(2)],'x'); set(ax(1),'xLim',xlims);
    set(gca,'Box', 'off', 'TickDir','out','TickLength',[.02 .02],'XMinorTick','on','YMinorTick','on', 'YGrid','on')
    set(gca,'XColor' , [.3 .3 .3], 'LineWidth', 1);
    set(ax(2),'XTick',[])
    ch = get(h1,'child'); set(ch,'EdgeAlpha',.3)
    
    
    title([int2str(tMin(c)) 'CE and before' ],style_l{:});
end
suptitle('Effect of record length','Fontweight','Bold')

set(gcf,'units','normalized','position',[0.1 0.1 0.6 0.4])
%hepta_figprint(['./figs/compositeByLatitude_' options.source],800)
froot = ['./figs/' opstring '_compositeByStartDate'];
hepta_figprint(froot,400)  %export to PDF as one needs to adjust transparency manually in Illustrator.
eps2pdfMac([froot '.eps'])