%% 实验3
clc, clear all;
addpath('./utils/');

times  = 20;
%任务个数
task_num = 5;
% 定义测试nMSE、rMSE、wR的变量

arr_nMSE_cFSGL = zeros(times, 1);

arr_rMSE_t_cFSGL = cell(times,1);


arr_nMSE_TGL = zeros(times, 1);

arr_rMSE_t_TGL = cell(times,1);


arr_nMSE_Lasso = zeros(times, 1);

arr_rMSE_t_Lasso = cell(times,1);

arr_wR_Lasso = zeros(times, 1);  

arr_wR_cFSGL = zeros(times, 1);

arr_wR_TGL = zeros(times, 1);



parfor i = 1:times
    fprintf('times: %d  (Lasso) ' ,i);
    [arr_nMSE_Lasso(i),arr_rMSE_t_Lasso{i},arr_wR_Lasso(i)] =  test_Lasso();%执行结果
end

nMSE_mean_Lasso = nanmean(arr_nMSE_Lasso);
nMSE_std_Lasso = nanstd(arr_nMSE_Lasso);


 
parfor i = 1:times
    fprintf('times: %d  (TGL) ' ,i);
    [arr_nMSE_TGL(i),arr_rMSE_t_TGL{i},arr_wR_TGL(i)]     =  test_TGL();  %执行结果
end

nMSE_mean_TGL = nanmean(arr_nMSE_TGL);
nMSE_std_TGL = nanstd(arr_nMSE_TGL);



parfor i = 1:times
    fprintf('times: %d  (cFSGL) ' ,i);
    [arr_nMSE_cFSGL(i),arr_rMSE_t_cFSGL{i},arr_wR_cFSGL(i)] =  test_cFSGL();%执行结果
end

nMSE_mean_cFSGL = nanmean(arr_nMSE_cFSGL);
nMSE_std_cFSGL = nanstd(arr_nMSE_cFSGL);



mat_rmse_t_cFSGL = reshape(cell2mat(arr_rMSE_t_cFSGL),task_num,times);
mat_rmse_mean_t_cFSGL = mean(mat_rmse_t_cFSGL,2);
mat_rmse_std_t_cFSGL = std(mat_rmse_t_cFSGL,0,2);


mat_rmse_t_TGL = reshape(cell2mat(arr_rMSE_t_TGL),task_num,times);
mat_rmse_mean_t_TGL = mean(mat_rmse_t_TGL,2);
mat_rmse_std_t_TGL = std(mat_rmse_t_TGL,0,2);


mat_rmse_t_Lasso = reshape(cell2mat(arr_rMSE_t_Lasso),task_num,times);
mat_rmse_mean_t_Lasso = mean(mat_rmse_t_Lasso,2);
mat_rmse_std_t_Lasso = std(mat_rmse_t_Lasso,0,2);



wR_mean_Lasso = nanmean(arr_wR_Lasso);
wR_std_Lasso = nanstd(arr_wR_Lasso);

wR_mean_TGL = nanmean(arr_wR_TGL);
wR_std_TGL = nanstd(arr_wR_TGL);

wR_mean_cFSGL = nanmean(arr_wR_cFSGL);
wR_std_cFSGL = nanstd(arr_wR_cFSGL); 