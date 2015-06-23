function [labeled_xys,feature_vectors,avg_similarity_matrix] = ...
    label_objects_all_floorplans(dataset_dir,data_output_dirname)



% enable parfor
pools = matlabpool('size');
cpus_available = feature('numCores');
if cpus_available > 8
    cpus = 8;
else
    cpus = cpus_available;% - 1; %UNCOMMENT IF USING SEYKHL
end
if pools ~= cpus
    if pools > 0
        matlabpool('close');
    end
    matlabpool('open', cpus);
end

%start by getting plan directory names 
tmp_dir_names = dir(dataset_dir);
dir_names = [];
for i = 1:length(tmp_dir_names)
    if((tmp_dir_names(i).isdir) && ~(strcmp(tmp_dir_names(i).name,'.'))...
        && ~(strcmp(tmp_dir_names(i).name,'..')))
        dir_names = [dir_names;tmp_dir_names(i).name];
    end %if
end %for i
[num_floorplans,~] = size(dir_names);

% then loading up fvcell and xy_label
feature_vectors = cell(num_floorplans,1);
labeled_xys = cell(num_floorplans,1);
temp_labels_by_floorplan = zeros(num_floorplans,1);
for i = 1:num_floorplans
    read_dir = strcat(dataset_dir,dir_names(i,:),'/',data_output_dirname)
    tmp_xys = load(strcat(read_dir,'/object_xy_with_label.mat'),...
                   'xy_with_label');
    [rows,cols] = size(tmp_xys.xy_with_label);
    labelmat = zeros(rows,cols+1);
    labelmat(1:rows,1) = 0; labelmat(:,2:4) = tmp_xys.xy_with_label;
    labeled_xys{i} = labelmat;
    %need to use xy_with_label here to combine feature_vectors from the
    %same object
    max_tmp_label = max(labelmat(:,4));
    temp_labels_by_floorplan(i) = max_tmp_label;
    %display(rows);
    %display(max_tmp_label);
    tmp_fvcell = load(strcat(read_dir,'/phow_hist_fvcell.mat'));
    if (rows == max_tmp_label)
        %fprintf('no combining needed\n');
        feature_vectors{i} = tmp_fvcell.fvcell;
    else
%         fprintf('need to combine for i = %d: rows=%d, max_tmp_label=%d\n',i,rows,max_tmp_label);
%         fprintf('before concatenation\n');
%         display(tmp_fvcell.fvcell);
        combined_fvcell = cell(max_tmp_label,1);
        for j = 1:max_tmp_label
            current_tmp_label = labelmat(j,4);
            current_fvcell = tmp_fvcell.fvcell{j};
            for k = j+1:rows
                next_tmp_label = labelmat(k,4);
                if (current_tmp_label == next_tmp_label)
                    %need to concatenate
                    current_fvcell = [current_fvcell;tmp_fvcell.fvcell{k}];
                end %if
            end %for k
            combined_fvcell{j} = current_fvcell;
        end %for j
        feature_vectors{i} = combined_fvcell;
%         fprintf('after concatenation\n');
%         display(feature_vectors{i});
    end %if
    %clear tmp_xys;
end %for i

%now do comparisons between image feature vectors across floorplans
M = sum(temp_labels_by_floorplan);
avg_similarity_matrix = zeros(M,'single');

for i = 1:M %map-vector
    [new_i,new_j] = find_indices(i,temp_labels_by_floorplan);
    [num_img_i,~] = size(feature_vectors{new_i}{new_j});
    for j = i:M %trying with self-similarity instead of i+1:M map-vector
        [new_i2,new_j2] = find_indices(j,temp_labels_by_floorplan);
        [num_img_j,~] = size(feature_vectors{new_i2}{new_j2});
        simi_matrix = zeros(num_img_i,num_img_j,'single');
        for k = 1:num_img_i %let with 2 nested map-vectors
            hist1 = feature_vectors{new_i}{new_j}(k,:);
            parfor l = 1:num_img_j
                hist2 = feature_vectors{new_i2}{new_j2}(l,:);
                simi_matrix(k,l)= 1 - pdist2(hist1,hist2,'chisq');
            end %parfor l
        end %for k
        avg_simi = max(mean(simi_matrix,1));
        avg_simi2 = max(mean(simi_matrix,2));
        avg_similarity_matrix(i,j) = avg_simi;
        avg_similarity_matrix(j,i) = avg_simi2; 
    end %for j
end %for i

%now look at avg_similarity values to determine which are alike
%diagonal elements are self-similarity--look in row and column to see if
%any other values are higher

%%START HERE%%
 
% unique_label = 1; %first unique label value
% labels = zeros(M,1);
% while (min(labels) == 0) %keep going until all labels set
%     for i = 1:M
%         if (labels(i) == 0)  %only do stuff if label not already set
%             [~,rowidx] = max(avg_similarity_matrix(i,:));
%             [~,colidx] = max(avg_similarity_matrix(:,i));
%             if ((rowidx == i) && (colidx == i)) %we have a new unique label
%                 labels(i) = unique_label;
%                 unique_label = unique_label + 1;
%             elseif (colidx ~= i) %copy label from colidx
%                 labels(i) = labels(colidx);
%             elseif (rowidx ~= i) %copy label from rowidx
%                 labels(i) = labels(rowidx);
%             else
%                 fprintf('THIS SHOULDN''T HAPPEN');
%             end % if row && col
%         end %if        
%     end %for i
% end %while
% xy_with_label(:,3) = labels; %done with this
% 
% %now do sorting and saving

%%DON'T FORGET TO SOMEHOW GIVE IMAGES UNIQUE NAMES BY FLOORPLAN (FLOORPLANS
%%ARE ALREADY UNIQUE)

% outfilename = strcat(img_dir,'/object_xy_with_label.mat');
% save(outfilename,'xy_with_label'); %object locations/labels saved
% outfilename2 = strcat(img_dir,'/phow_hist_fvcell.mat');
% save(outfilename2,'fvcell'); %phow histograms saved to file
% 
% for i = 1:(unique_label - 1)
%     new_dir = strcat(img_dir,'fplabel',num2str(i),'/');
%     if (exist(new_dir,'dir'))
%         rmdir(new_dir,'s'); %get rid of old data
%     end %if
%     mkdir(new_dir); %make fplabel directories
% end %for i
% 
% for i = 1:M %for each temp label
%     src_dir = strcat(img_dir,'tmp',num2str(i),'/');
%     src_file_list = dir(src_dir);
%     num_files = numel(src_file_list) - 2; % -2 is because of . and ..
%     dest_dir = strcat(img_dir,'fplabel',num2str(xy_with_label(i,3)),'/');
%     for j = 1:num_files %for each image in tmpN dir
%         src = strcat(src_dir,src_file_list(j+2).name);
%         dest = strcat(dest_dir,src_file_list(j+2).name);
%         movefile(src,dest);
%     end %for j
%     rmdir(src_dir,'s');
% end %for i

matlabpool('close'); %kill parallel workers
end %function (main)

function [i_out,j_out] = find_indices(i_in,M)
    len = numel(M);
    for a = 1:len
        running_total = sum(M(1:a));
        if (i_in <= running_total)
            i_out = a;
            j_out = i_in - sum(M(1:a-1));
            return;
        end %if
    end %for a
end %function

%%%%%%%%%%%%%%%%%%%%%%%OLD HEADER COMMENTS FROM
%%%%%%%%%%%%%%%%%%%%%%%SORT_CLUSTERS_SINGLE_FLOORPLAN
%This function takes the images sorted into clusters (tmpN directories) and
%finds the like objects, then re-sorts the images into new directories and
%returns the xy locations with labels (like objects labeled alike)

%ALSO moves the files from the tmp* directories into fplabel* directories
%based on floorplan labels, and saves the xy_with_label data to a .mat file

%inputs: objectxys: M x 2 matrix of cluster center xy locations
%        img_dir: directory where detection images are
%output: xy_with_label M x 3 matrix of [x y label]

%%???could call sort_by_cluster here if I add cluster_data as an argument