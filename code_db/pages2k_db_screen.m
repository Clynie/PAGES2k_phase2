% Compare the difference of instrumental records on annual vs seasonal scales.
function pages2k__db_screen(vers,options)
% function pages2k__db_screen(vers,options)
%  INPUT:   vers (version of the database, string)
%           options: structured array with fields:
%         - dtype: string (pre-processing of timeseries, options are: detrending, first-difference of the original time series, and the original)
%         - search_radius: float (radius within which to seek temperature neighbors)
%         - norm_p: boolean (1=> Gaussianized proxies; 0 => raw proxies)
%         - num: integer;  process proxies by block to save time
%         - nsim: integer (# of surrogate timeseries in non-parametric tests)
%
%  OUTPUT:  raw time series and correlation maps of each record vs. MAT,
%           JJA, DJF temperature (source: infilled hadcrut4)
%
% Tasks: individual record visual check, especially its sensitivity to
% temeperature with respect to seasonality
year = []; warning off
addpath(genpath('../utilities'));
fn = ['../data/PAGES2k_v' vers '_unpack.mat'];
load(fn)

% process options
search_radius = options.search_radius;
norm_p = options.norm_p;
dtype  = options.dtype;
method = options.method;
sample_thresh = options.sample_thresh;

%% Prepare temperature data
tmp  = load('../data/had4med_graphem_sp70');  % TO DO: make this more general: should be able to load any temperature dataset, if stored under a more generic name
ti   = unique(tmp.tvec(1:1968,1));  % TO DO: remove ad-hockeries
temp = tmp.Xf(1:1968,:); % 164 full calendar years from Jan 1850 - Dec 2013

t     = year(year>0);
% Overlapping period (proxy vs. temperature)
tc    = intersect(ti,t);
tcal  = ismember(ti,tc);
pcal  = ismember(t,tc);

% TO DO: use intra_temp_ann_avg2.m
% temp_ann
temp_ann = (temp(1:12:end,:) + temp(2:12:end,:) + temp(3:12:end,:) + ...
    temp(4:12:end,:) + temp(5:12:end,:) + temp(6:12:end,:) + ...
    temp(7:12:end,:) + temp(8:12:end,:) + temp(9:12:end,:) + ...
    temp(10:12:end,:) + temp(11:12:end,:) + temp(12:12:end,:))./12;
% JJA
temp_jja = (temp(6:12:end,:) + temp(7:12:end,:) + temp(8:12:end,:))./3;
% DJF
temp_djf = (temp(12:12:end,:) + temp(1:12:end,:) + temp(2:12:end,:))./3;
% tropical year
temp_ama = (temp(4:12:end-12,:) + temp(5:12:end-12,:) + temp(6:12:end-12,:) + ...
    temp(7:12:end-12,:) + temp(8:12:end-12,:) + temp(9:12:end-12,:) + ...
    temp(10:12:end-12,:) + temp(11:12:end-12,:) + temp(12:12:end-12,:) + ...
    temp(12+1:12:end,:) + temp(12+2:12:end,:) + temp(12+3:12:end,:))./12;

% Restrict temperatura and proxy to the overlapping period
temp_ann = temp_ann(tcal,:);
temp_jja = temp_jja(tcal,:);
temp_djf = temp_djf(tcal,:);
temp_ama = temp_ama(tcal,:);

% Remove duplicate records
if norm_p
    disp('Normalize proxy before calculating correlations')
    norm_string = 'normal';
    proxc_ann = gaussianize(proxy_ann(pcal,:));
    proxc_djf = gaussianize(proxy_djf(pcal,:));
    proxc_jja = gaussianize(proxy_jja(pcal,:));
    proxc_ama = gaussianize(proxy_ama(pcal,:));
else
    norm_string = 'raw';
    proxc_ann = proxy_ann(pcal,:);
    proxc_djf = proxy_djf(pcal,:);
    proxc_jja = proxy_jja(pcal,:);
    proxc_ama = proxy_ama(pcal,:);
end

avl_ann = ~isnan(proxc_ann);
avl_djf = ~isnan(proxc_djf);
avl_jja = ~isnan(proxc_jja);
avl_ama = ~isnan(proxc_ama);


ns    = size(temp,2);
nr    = length(S);

%% detrending   % TO DO: implement more sophisticated detrending (splines?)
per = {'ann','djf','jja','ama'};
if strcmp(dtype,'detrend')
    disp('Detrend proxies before calculating correlations')
    temp_ann = detrend(temp_ann);  temp_ama = detrend(temp_ama);
    temp_jja = detrend(temp_jja);  temp_djf = detrend(temp_djf);

    for v = 1:nr
        for s = 1:3
            eval(['Xa = proxc_' per{s} '(:,v);']);
            ta = tc;
            if sum(avl_ann(:,v))>10
                [~,~,segment] = find_breaks(ta,Xa);
                nseg = length(segment);
                dtd  = NaN*Xa;
                if nseg > 1  % if more than 1 segment
                    for i=1:nseg;
                        ds = Xa(segment{i});
                        dtd(segment{i}) = detrend(ds);
                    end
                else
                    ind = ~isnan(Xa);
                    ds = Xa(ind);
                    % Maker sure they are column vectors
                    dtd(ind) = detrend(ds);
                end
                eval(['proxc_' per{s} '(ismember(tc,ta),v) = dtd;']);
            end
        end
    end
elseif strcmp(dtype,'diff1')
    disp('Get the first difference before calculating correlations')
    % or first-difference
    temp_ann = diff(temp_ann);  temp_jja = diff(temp_jja); temp_djf = diff(temp_djf);
    proxc_ann  = diff(proxc_ann);  avl_ann  = ~isnan(proxc_ann);
    proxc_djf  = diff(proxc_djf);
    proxc_jja  = diff(proxc_jja);
    proxc_ama  = diff(proxc_ama); avl_ama  = ~isnan(proxc_ama);

elseif strcmpi(dtype,'noDetrend')
    disp('No proxy detrending prior to calculating correlations')
end

%% Proxy-temperature distance
locs      = tmp.loc;
c         = pi/180;
d_pt      = zeros(nr,ns);
d_pp      = zeros(nr,nr-1);
idx_loc   = nan(nr,1);
idx_neigh = cell(1,nr);
display('Calculate proxy-temperature & proxy-proxy distances')

for r = 1:nr
    % Proxy-temperature distances
    d_pt(r,:) = greatCircleDistance(c*locs(:,2), c*locs(:,1), c*p_lat(r), c*p_lon(r));
    % Index of the closest temperature neighbor
    [~,idx] = sort(d_pt(r,:));
    idx_neigh{r} = find(d_pt(r,:) <= search_radius);
    idx_loc(r)   = idx(1);
    % Proxy-proxy distances
    ii = setdiff(1:nr,r);
    d_pp(r,:) = greatCircleDistance(c*p_lat(ii), c*p_lon(ii), c*p_lat(r), c*p_lon(r));
end
[d_sort,idx_pp] = sort(d_pp,2); % first row is the closest proxy neighbors for each record

save ../data/distances.mat d_sort d_pp d_pt idx_loc idx_pp idx_neigh



%% Calculate Proxy-temperature correlation
rho_mat = nan(ns,nr); sig_mat = nan(ns,nr); pval_mat = nan(ns,nr);
rho_djf = nan(ns,nr); sig_djf = nan(ns,nr); pval_djf = nan(ns,nr);
rho_jja = nan(ns,nr); sig_jja = nan(ns,nr); pval_jja = nan(ns,nr);
rho_ama = nan(ns,nr); sig_ama = nan(ns,nr); pval_ama = nan(ns,nr);

preg_mat = nan(nr,1); preg_djf = nan(nr,1);   preg_jja = nan(nr,1); preg_ama = nan(nr,1);
ploc_mat = nan(nr,1); ploc_djf = nan(nr,1);   ploc_jja = nan(nr,1); ploc_ama = nan(nr,1);
n_sig_mat = nan(nr,1); n_sig_djf = nan(nr,1); n_sig_jja = nan(nr,1);  n_sig_ama = nan(nr,1);

op.nsim = options.nsim; % number of surrogates for isospectral test
qBC = 0.05; % Target false discovery rate (knockoff, Barber & Candes 2015)
qBH = 0.05; % Target false discovery rate (Benjamini-Hochberg 1995)
% output file
fname = ['../data/pages2k_hadcrut4_corr_' dtype '_' vers '_' norm_string '_' method '.mat'];


for r = 1:nr
    disp(['Processing proxy ' num2str(r)])
    nz_ann = avl_ann(:,r); n = sum(nz_ann);
    nz_djf = avl_djf(:,r); nz_jja = avl_jja(:,r); nz_ama = avl_ama(:,r);
    T = S(r);
    n_raw_samples(r) = numel(T.paleoData_values);
    n_ann_samples(r) = sum(~isnan(proxc_ann(:,r)));
    % Only evaluate P-T relationships if at least 'samples_thresh' temp_ann measurements are available during instrumental period
    if n_raw_samples(r) >= sample_thresh & n_ann_samples(r) >= sample_thresh
        if resMed(r) <= 5               % hi-res proxies
            mat = temp_ann;   ama = temp_ama;
            djf = temp_djf;   jja = temp_jja;

        else
            % Low-res proxies, temperature also needs to be
            % lowpass-filtered in order for correlations to be meaningful
            fc = 1/(2*resMed(r));
            for j = idx_neigh{r}
                mat(:,j) = hepta_smooth(temp_ann(:,j),fc);
                djf(:,j) = hepta_smooth(temp_jja(:,j),fc);
                jja(:,j) = hepta_smooth(temp_djf(:,j),fc);
                ama(:,j) = hepta_smooth(temp_ama(:,j),fc);
            end
        end
        switch method
            case {'isospectral','ttest','isopersistent'}
                op.method = method;

                % Identify significant features via corr_sig
                for s = idx_neigh{r}
                    [rho_mat(s,r),sig_mat(s,r),pval_mat(s,r)] = corr_sig(mat(nz_ann,s),proxc_ann(nz_ann,r),op);
                    [rho_djf(s,r),sig_djf(s,r),pval_djf(s,r)] = corr_sig(djf(nz_djf,s),proxc_djf(nz_djf,r),op);
                    [rho_jja(s,r),sig_jja(s,r),pval_jja(s,r)] = corr_sig(jja(nz_jja,s),proxc_jja(nz_jja,r),op);
                    [rho_ama(s,r),sig_ama(s,r),pval_ama(s,r)] = corr_sig(ama(nz_ama,s),proxc_ama(nz_ama,r),op);

                end

                % Define screening criteria (local correlation, regional
                % correlation, regional correlation that corrects for FDR)
                % 1) maximum regional correlation
                [~,jmax]    = max(abs(rho_mat(:,r)));  % mat
                preg_mat(r) = pval_mat(jmax,r);
                [~,jmax]    = max(abs(rho_djf(:,r)));  % djf
                preg_djf(r) = pval_djf(jmax,r);
                [~,jmax]    = max(abs(rho_jja(:,r)));  % jja
                preg_jja(r) = pval_jja(jmax,r);
                [~,jmax]    = max(abs(rho_ama(:,r)));  % ama
                preg_ama(r) = pval_ama(jmax,r);
                % 2) local correlation
                ploc_mat(r) = pval_mat(idx_loc(r),r);  % mat
                ploc_djf(r) = pval_djf(idx_loc(r),r);  % djf
                ploc_jja(r) = pval_jja(idx_loc(r),r);  % jja
                ploc_ama(r) = pval_ama(idx_loc(r),r);  % ama

                % 3) FDR with Venura [2004] power boosting adjustment
                n_sig_mat(r)= fdr(pval_mat(idx_neigh{r},r),qBH,'original','mean');  % mat idx_neigh{r}
                n_sig_djf(r)= fdr(pval_djf(idx_neigh{r},r),qBH,'original','mean');  % djf
                n_sig_jja(r)= fdr(pval_jja(idx_neigh{r},r),qBH,'original','mean');  % jja
                n_sig_ama(r)= fdr(pval_ama(idx_neigh{r},r),qBH,'original','mean');  % ama


            case 'knockoff'  %TODO: include ama screening
                % Identify significant features via the Knockoff filter
                % Barber & Candes, Controlling the False Discovery Rate via Knockoffs, http://arxiv.org/abs/1404.5609
                n = sum(nz); % number of samples
                %% Compute regional correlations
                rho_mat(idx_neigh{r},r) = corr(mat(nz_ann,idx_neigh{r}),proxc_ann(nz_ann,r));
                rho_jja(idx_neigh{r},r) = corr(jja(nz_jja,idx_neigh{r}),proxc_jja(nz_jja,r));
                rho_djf(idx_neigh{r},r) = corr(djf(nz_djf,idx_neigh{r}),proxc_djf(nz_djf,r));

                if n < idx_neigh{r} % if "n < p" case
                    iNeigh = find(d_pt(r,:) <= search_radius,n-1); % find n-1 closest neighbors
                else
                    iNeigh = idx_neigh{r};
                end

                % temp_ann
                X = mat(nz,iNeigh);  y = proxc_ann(nz_ann,r);
                S_ann{r} = knockoff.filter(X, y, q,'Knockoffs','sdp'); n_sig_mat(r) = numel(S_ann);
                % DJF
                X = djf(nz,iNeigh);  y = proxc_djf(nz_djf,r);
                S_djf{r} = knockoff.filter(X, y, q,'Knockoffs','sdp'); n_sig_djf(r) = numel(S_djf);
                % JJA
                X = jja(nz,iNeigh);  y = proxc_jja(nz_jja,r);
                S_jja{r} = knockoff.filter(X, y, q,'Knockoffs','sdp'); n_sig_jja(r) = numel(S_jja);

                % Define screening criteria
                % 1) maximum regional correlations
                [rMaxMAT(r),jmax] = max(abs(rho_mat(:,r)));  % mat
                [~,~,preg_mat(r)] = corr_sig(mat(nz,jmax),proxc_ann(nz,r),options); % estimate significance
                [rMaxDJF(r),jmax] = max(abs(rho_djf(:,r)));  % djf
                [~,~,preg_mat(r)] = corr_sig(djf(nz,jmax),proxc_djf(nz,r),options); % estimate significance
                [rMaxJJA(r),jmax] = max(abs(rho_jja(:,r)));  % jja
                [~,~,preg_mat(r)] = corr_sig(jja(nz,jmax),proxc_jja(nz,r),options); % estimate significance
                % 2) local correlations
                [rLocMAT(r),sigLocMAT(r),ploc_mat(r)] = corr_sig(mat(nz_ann,idx_loc(r)),y,options);
                [rLocDJF(r),sigLocDJF(r),ploc_djf(r)] = corr_sig(djf(nz_djf,idx_loc(r)),y,options);
                [rLocJJA(r),sigLocJJA(r),ploc_jja(r)] = corr_sig(jja(nz_ann,idx_loc(r)),y,options);
                % 3) FDR (Knockoff style)
                n_sig_mat(r)= ~isempty(S_ann{r}); % mat
                n_sig_djf(r)= ~isempty(S_jja{r}); % jja
                n_sig_jja(r)= ~isempty(S_djf{r}); % djf
        end
    end

    % Save output
    %if length(num) == length(no_dup)
    %    fname = ['../../data/corr_hadcrut/pages2k_hadcrut4_corr_' dtype '_' vers '_' norm_string '_' method];
    %else
    %    nest  = [num2str(num(1)), '-', num2str(num(end))];
    %    fname = ['../../data/corr_hadcrut/pages2k_hadcrut4_corr_' dtype '_' vers '_' norm_string  '_' method '_' nest];
    %end
    save(fname,'idx_loc','idx_neigh','rho_mat','sig_mat','rho_jja','sig_jja','rho_djf','sig_djf','rho_ama','sig_ama','pval_mat','pval_djf','pval_jja','pval_ama','d_pt','d_pp');
end


% Screening
season = {'mat','djf','jja','ama'}; nl = length(season);
cmethod = {'reg','fdr','loc'}; nm = length(cmethod);
note   = 'In each of the screen_* files, indices correspond to MAT, DJF, JJA, respectively';
screen_fdr = cell(1,nl); screen_reg = cell(1,nl); screen_loc = cell(1,nl);
screen_mtx = zeros(nm,nl);

for i = 1:nl
    screen_reg{i} = eval(['find(preg_' season{i} '<=0.05)']);
    screen_mtx(1,i) = numel(screen_reg{i});
    screen_fdr{i} = eval(['find(n_sig_' season{i} '>0)']);
    screen_mtx(2,i) = numel(screen_fdr{i});
    screen_loc{i} = eval(['find(ploc_' season{i} '<=0.05)']);
    screen_mtx(3,i) = numel(screen_loc{i});
end

% Save output
save(fname,'screen_fdr','screen_reg','screen_loc','pval_mat','pval_djf','pval_jja','note','season','ploc_mat','ploc_jja','ploc_djf','-append')
save(fname,'preg_mat','preg_djf','preg_jja','n_sig_mat','n_sig_djf','n_sig_jja','-append')

tname = ['../data/pages2k_hadcrut4_corr_' dtype '_' vers '_' norm_string '_' method '.tex'];
latextable(screen_mtx,'Horiz',season,'Vert',cmethod,'name',tname,'Hline',1,'Vline',1,'format','%d');


if strcmpi(method,'knockoff')
    save(fname,'S_ann','S_djf','S_jja','-append')
end

% plot p-values

% for r = 1:20
%     psort = sort(pval_mat(idx_neigh{r},r)); m = length(psort);
%     ii = [1:m]/m;
%     clf
%     semilogy(ii,psort,'k.',ii,ii*qBH,'r-')
%     title(S(r).dataSetName)
%     n_sig_mat(r) = fdr(pval_mat(idx_neigh{r},r),qBH,'original','mean');  % mat
%     n_sig_djf(r) = fdr(pval_djf(idx_neigh{r},r),qBH,'original','mean');  % djf
%     n_sig_jja(r) = fdr(pval_jja(idx_neigh{r},r),qBH,'original','mean');
% end

% % Put nests back to a single file
% dtype = 'noDetrend'; vers = '2015_04_14'; norm_string = 'raw';
% screen_fdr = {[],[],[]}; screen_reg = {[],[],[]}; screen_loc = {[],[],[]};
% for i = 1:20
%     if i<20
%         num = (i-1)*50 + 1: i*50;
%     elseif i == 20
%         num = 951:990;
%     end
%     nest  = [num2str(num(1)), '-', num2str(num(end))];
%     fname = ['../../data/corr_hadcrut/pages2k_hadcrut4_corr_' dtype '_' vers '_' norm_string '_' nest];
%     tmp   = load(fname);
%     for j = num
%         rho_mat(tmp.idx_neigh{j},j) = tmp.rho_mat(tmp.idx_neigh{j},j);
%         rho_djf(tmp.idx_neigh{j},j) = tmp.rho_djf(tmp.idx_neigh{j},j);
%         rho_jja(tmp.idx_neigh{j},j) = tmp.rho_jja(tmp.idx_neigh{j},j);
%         % p-value
%         pval_mat(tmp.idx_neigh{j},j) = tmp.pval_mat(tmp.idx_neigh{j},j);
%         pval_djf(tmp.idx_neigh{j},j) = tmp.pval_djf(tmp.idx_neigh{j},j);
%         pval_jja(tmp.idx_neigh{j},j) = tmp.pval_jja(tmp.idx_neigh{j},j);
%         % significance
%         sig_mat(tmp.idx_neigh{j},j) = tmp.sig_mat(tmp.idx_neigh{j},j);
%         sig_djf(tmp.idx_neigh{j},j) = tmp.sig_djf(tmp.idx_neigh{j},j);
%         sig_jja(tmp.idx_neigh{j},j) = tmp.sig_jja(tmp.idx_neigh{j},j);
%
%     end
%     for k = 1:nl
%         screen_fdr{k} = [screen_fdr{k}; tmp.screen_fdr{k}];
%         screen_reg{k} = [screen_reg{k}; tmp.screen_reg{k}];
%         screen_loc{k} = [screen_loc{k}; tmp.screen_loc{k}];
%     end
%
% end
%
% % Check to make sure things are properly loaded
% n = 0;
% for p = 1:nr
%     if sum(~isnan(rho_mat(tmp.idx_neigh{p},p)))	~= length(tmp.idx_neigh{p})
%         n = n+1;
%         lr(n) = p;
%         if avail(:,p) > 10
%             error('Loading incorrect')
%         end
%     end
%     % 1) maximum regional correlation
%     [~,jmax]    = max(abs(rho_mat(:,p)));  % mat
%     preg_mat(p) = pval_mat(jmax,p);
%     [~,jmax]    = max(abs(rho_djf(:,p)));  % djf
%     preg_djf(p) = pval_djf(jmax,p);
%     [~,jmax]    = max(abs(rho_jja(:,p)));  % jja
%     preg_jja(p) = pval_jja(jmax,p);
%     % 2) local correlation
%     ploc_mat(p) = pval_mat(tmp.idx_loc(p),p);  % mat
%     ploc_djf(p) = pval_djf(tmp.idx_loc(p),p);  % djf
%     ploc_jja(p) = pval_jja(tmp.idx_loc(p),p);  % jja
%     % 3) FDR
%     n_sig_mat(p)= fdr(pval_mat(:,p),0.05);  % mat
%     n_sig_djf(p)= fdr(pval_djf(:,p),0.05);  % djf
%     n_sig_jja(p)= fdr(pval_jja(:,p),0.05);  % jja
% end
% if sum(find(sum(avail,1)<=10) - lr) ~=0
%     error('Something is wrong!')
% else
%     display('nested files are put together correctly!')
% end
%
% nr = length(idx_loc);
% for r = 1:nr
%     ploc_mat(r) = pval_mat(idx_loc(r),r);  % mat
%     ploc_djf(r) = pval_djf(idx_loc(r),r);  % djf
%     ploc_jja(r) = pval_jja(idx_loc(r),r);  % jja
%     [~,jmax]    = max(abs(rho_mat(:,r)));  % mat
%     preg_mat(r) = pval_mat(jmax,r);
%     [~,jmax]    = max(abs(rho_djf(:,r)));  % djf
%     preg_djf(r) = pval_djf(jmax,r);
%     [~,jmax]    = max(abs(rho_jja(:,r)));  % jja
%     preg_jja(r) = pval_jja(jmax,r);
%     % 3) FDR with Venura [2004] power boosting adjustment
%     n_sig_mat(r)= fdr(pval_mat(idx_neigh{r},r),qBH,'original','mean');  % mat idx_neigh{r}
%     n_sig_djf(r)= fdr(pval_djf(idx_neigh{r},r),qBH,'original','mean');  % djf
%     n_sig_jja(r)= fdr(pval_jja(idx_neigh{r},r),qBH,'original','mean');  % jja
% end
