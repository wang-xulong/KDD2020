function [wR,Placeholder] = eval_MTL_wR(Y,X,W)
%��Ȩ��ϵϵ���Ĺ���
%������=5�����ó�ʼֵΪ0������������������Ϊ0
    task_num = length(X);
    wR = 0;
    total_sample = 0;
    Placeholder = zeros(task_num,1);%ռλ����Ϊ��ͳһ�����ӿڣ�û��ʵ������
    
    for i = 1: task_num
        y_pred = X{i} * W(:, i);
        corr = corrcoef(Y{i},y_pred);%��������ϵ������
        wR = wR + corr(1,2) * length(y_pred);
        total_sample = total_sample + length(y_pred);
    end
    wR = wR / total_sample;
end



