function xy= spline_centerline(xy,N_fil,ds,np)

nend=cell(max(N_fil),1);
for i = 1 : max(N_fil)
    nend{i} = 0.5*cellfun(@numel,xy(i).crd); % number of coordinates
end

for i = 1 : max(N_fil)
    for j = 1 : xy(i).nframe
        
        cum = cumsum(xy(i).seglen{j}(:,1)); % array of the cumulative sum of centerline segments (cum(end)==arclen!!)
        
        % remainder of the division between cum and ds.
        % Minima are found when the partial sum of the segments is a multiple of ds
        
        modulo = mod(cum,ds);
        
        % obtain these local minima and the corresponding array of index. For these indexes,
        % the arclength is an integer multiple of ds. The corresponding  centerline coordinates are thus equispaced
        
        posmin{i,j} = find(islocalmin(modulo)==1);
        posmin{i,j}=[1;posmin{i,j}+1;nend{i}(j)]; %
        
    end
end

%% arrange the centerline coordinates (knots) to be passed to the b-spline function


for i = 1 : max(N_fil)
    for j = 1 : xy(i).nframe
        
        % KNOTS(i,j) gives the j-th coordinate of the i-th knot. The knots can be of any dimension
        knots{i,j} = [xy(i).crd{j}(posmin{i,j},1),xy(i).crd{j}(posmin{i,j},2)];
        xy(i).spl{j} = BSpline(knots{i,j},'order',2,'nint',np);
        xy(i).knots{j} = knots{i,j};
        [lspl,sspl] = arclength(xy(i).spl{j}(:,1),xy(i).spl{j}(:,2),'pchip');
        xy(i).arclen_spl(j) = lspl;
        xy(i).seglen_spl{j} = sspl;
    end
end

end

