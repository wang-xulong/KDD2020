%% FUNCTION Least_Lasso
% Sparse Structure-Regularized Learning with Least Squares Loss.
%
%% OBJECTIVE
% argmin_W { sum_i^t (0.5 * norm (Y{i} - X{i}' * W(:, i))^2)
%            + rho1 * \|W\|_1 + opts.rho_L2 * \|W\|_F^2}
%
%% INPUT
%   X: {n * d} * t - input matrix
%   Y: {n * 1} * t - output matrix
%   rho1: sprasity controlling parameter
%   opts.rho_L2: L2-norm regularization parameter
%
%% OUTPUT
%   W: model: d * t
%   funcVal: function value vector.
%
%% Related papers
%   [1] Tibshirani, J. Regression shrinkage and selection via
%   the Lasso, Journal of the Royal Statistical Society. Series B 1996
%
%% Related functions
%   Logistic_Lasso, init_opts
%
%% Code starts here
%w is the matrix weight
%funcVal is the function value of the last iteration of this model
%rho1 regularizaion parameter
%opts �ǳ�ʼ����Ĭ�ϲ������ã�����ָ��һЩ�㷨�����Ĭ�ϵĲ���ֵ���㷨�Ż�����������������ֹͣ�����ȵ�
function [W, funcVal] = Least_Ridge1(X, Y, rho1, opts)

if nargin <3 %���øú���ʱ�������Ĳ�������������ʾ���󣬲��˳�
    error('\n Inputs: X, Y, abd rho1 should be specified!\n');
end

% cell X array transpose ;every cell is n * d; when tansposed:
% row:feature number (d)
% column:sample number (n)
X = multi_transpose(X); 
if nargin <4
    opts = [];
end

opts=init_opts(opts);                                           % ��ʼ��Ĭ�ϲ���ѡ��

if isfield(opts, 'rho_L2')                                        % �Ƿ�opts��Ҫ�����L2��ʽ�����򻯲���
    rho_L2 = opts.rho_L2;
else
    rho_L2 = 0;                                                     % ���㷨��û��Ҫ����ӣ����rho_L2 = 0; 
end

rho_L2 = rho1;
task_num  = length (X);                                       % X contains many matrix(n x d)��the number of task number is length(X)

dimension = size(X{1}, 1);                                   % every cell's demension is d

funcVal = [];                                                         % store function value

%create cell to store result in every task
XY = cell(task_num, 1);

W0_prep = [];%

% initialize a weight
% every XY{t_idx} is the result of every task(dxn  x   nx1)
% put the result of every task(dxn  x   nx1) into W0_prep
% W0_prepΪÿ������������ֵ���ǩֵ�ĳ˻�������X*Y
% W0_prep���ǳ�ʼ��ģ��Ȩ�ص�һ�ַ�ʽ��ͬʱΪ�����������ṩ��������Ϊͬ��ʹ�õ���X*Y�Ľ��
for t_idx = 1: task_num                                        % ÿ���������α���
    XY{t_idx} = X{t_idx}*Y{t_idx};                          %  ��Ӧ X*Y
    W0_prep = cat(2, W0_prep, XY{t_idx});          %  ��ÿ�������X*Y�Ľ���洢��W0_prep��
end

% initialize a starting point
if opts.init==2
    W0 = zeros(dimension, task_num);                % ���㷨�У�opts.init==2����ʼ��Ȩ������Ϊ�����
elseif opts.init == 0
    W0 = W0_prep;
else
    if isfield(opts,'W0')
        W0=opts.W0;
        if (nnz(size(W0)-[dimension, task_num]))
            error('\n Check the input .W0');
        end
    else
        W0=W0_prep;
    end
end


bFlag=0;                                                             % this flag tests whether the gradient step only changes a little

%Wz��Wz_old��¼��һ�ε�ģ��Ȩ�غ����ϴε�ģ��Ȩ�أ��뵱ǰģ��Ȩ��Ws�й�
Wz= W0;
Wz_old = W0;
%t��t_old��¼��ǰģ��Ȩ�صĵ�����������ģ�Ͳ���alpha�й�
t = 1;
t_old = 0;


iter = 0;                                                               % ��ǰ��������
gamma = 1;                                                        % gammaΪ�Ż�Ŀ�꺯���������õ��ĳ����������������Ż����̵Ĳ����������Ŀ�꺯��������ֵ��
gamma_inc = 2;                                                 % gamma_incΪÿ�ε�����gamma�����ȣ�gamma = gamma * gamma_inc;

while iter < opts.maxIter                                     % �涨����������Ϊ100�� ���ⲿ����ʵ�ζ��壬opts.maxIter  = 100 
    alpha = (t_old - 1) /t;                                       % alphaΪ����ģ��Ȩ��Ws��ÿ�ε��������ж��ϴ�Ws�����ϴ�Ws���ۺϲο���
    
    Ws = (1 + alpha) * Wz - alpha * Wz_old;        % Ws��ÿ�ε��������вο��ϴ�Ws�����ϴ�Ws

    % compute function value and gradients of the search point
    gWs  = gradVal_eval(Ws);                              % gWs�Ǽ���Ws��RSS���ֵ��ݶ�ֵ�������κ����򻯵���ʧ������Ӧ���ݶ�ֵ��
    Fs   = funVal_eval  (Ws);                                % Fs��RSS(�в�ƽ����)����ʧ����ֵ
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ������while true ��Ŀ����ȷ��������L1��ʽԼ���µ�ģ��Ȩ�ؾ���
    % �����ֵķ�����͸??��ϣ�ĳ�?(Lipschitz Constant)��ȷ��һ���Ͻ�ֵ����������gamma��
    % Lipschitz Constant�ĺ���˼�����Ǵ���һ?��? L��?��?������???��б��??ֵ�����
    % ??��?��б�ʱ�����������Ͻ��ڣ���ʱֻҪѡ�񲽳�Ϊ1/gamma ���ɱ�֤������������
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    while true
        % ���㷨��ͨ��ʹ�ý����ݶ��½�������������
        % l1_projectionΪ�������ǰģ��Ȩ��W������L1Լ���£���L1Լ���ռ��е�ͶӰ��l1_projection���Կ���������ֵ����
        % Wzp�Ǿ���L1Լ���ռ���ͶӰ��Ȩ��ֵ����sumֵΪl1c_wzp
       % [Wzp, l1c_wzp] = l1_projection(Ws - gWs/gamma, 2 * rho1 / gamma);
        Wzp = Ws - gWs/gamma;
        % �����Wzp�Ĳв�ƽ����
        Fzp = funVal_eval  (Wzp);
        
        % delta_WzpΪL1Լ���ռ���ͶӰ��Ȩ��ֵWzp��δ������Լ����ģ��ȨֵWs,delta_WzpΪ����֮��ı仯��
        delta_Wzp = Wzp - Ws;
        % �����F��ʽ
        r_sum = norm(delta_Wzp, 'fro')^2;
        % Fzp_gamma��������ʧ������Wzp����̩�ն��׽���չ��ʽ�Ľ����
        % �����жϵ�ǰ��gamma�����Ƿ�����Lipschitz Constantd ����
        Fzp_gamma = Fs + sum(sum(delta_Wzp .* gWs)) + gamma/2 * sum(sum(delta_Wzp.*delta_Wzp));
        
        if (r_sum <=1e-20)                                     % ���r_sum��С�ˣ�˵��Լ��ǰ��ģ��Ȩ��ֵ�仯���󣬿���ֹͣ������
            bFlag=1;                                                 % this shows that, the gradient step makes little improvement
            break;
        end
        
        if (Fzp <= Fzp_gamma)                              % �ж��Ƿ�����Lipschitz Constant ����
            break;
        else
            gamma = gamma * gamma_inc;            % ����������������������gamma_inc == 2���˹����У�gamma����������������1/gamma���𽥼�С
        end
    end
    % while trueѭ����������ʱȨ�ؾ����ڵ����в��ٱ仯�����Ѿ��ҵ���������Lipschitz Constant
    % �����Ĳ���������������£����Ա�֤������������
    Wz_old = Wz;                                                 % ��¼����һ�ε�ģ��Ȩ�ؾ���
    Wz = Wzp;                                                      % ����������L1Լ����ģ��Ȩ�ؾ��󱣴浽Wz
    
    funcVal = cat(1, funcVal, Fzp);% �����˽����ʧ������ֵFzp + rho1 * l1c_wzp������funcVal��
    
    if (bFlag)                                                         % Ȩֵ�Ѿ��仯��С�����²����ˣ���ô�����˳�����
        % fprintf('\n The program terminates as the gradient step changes the solution very small.');
        break;
    end
    
    % test stop condition.
    switch(opts.tFlag)                                           % ������ֹ���������ڱ�ģ�͵��㷨��Ĭ����ѡ��case 1�����
        case 0
            if iter>=2
                if (abs( funcVal(end) - funcVal(end-1) ) <= opts.tol)
                    break;
                end
            end
        case 1
            if iter>=2
                % ������ε�������ʧֵ�ı仯���Ѿ�С�ڵ��ڵ����ڶ��ε�������ֵ����һ����С���� opts.tol
                if (abs( funcVal(end) - funcVal(end-1) ) <=...
                        opts.tol* funcVal(end-1))
                    break;
                end
            end
        case 2
            if ( funcVal(end)<= opts.tol)
                break;
            end
        case 3
            if iter>=opts.maxIter
                break;
            end
    end
    
    iter = iter + 1;                                                   % ��������+1
    t_old = t;                                                          % �����¾ɵı���t
    t = 0.5 * (1 + (1+ 4 * t^2)^0.5);                         % t ����
    
end

W = Wzp;


% private functions

%     function [z, l1_comp_val] = l1_projection (v, beta)%v�Ǹ��º��Ȩ��W��ֵ
%         %l1_projection��������ֵ(soft thresholding) 
%         % this projection calculates    
%         % argmin_z = \|z-v\|_2^2 + beta \|z\|_1
%         % z: solution
%         % l1_comp_val: value of l1 component (\|z\|_1)
%         z = sign(v).*max(0,abs(v)- beta/2);
%          
%         l1_comp_val = sum(sum(abs(z)));
%     end

    function [grad_W] = gradVal_eval(W)%�õ�RSS���ֵ�ƫ��(�ݶ�)ֵ
        grad_W = [];
        for t_ii = 1:task_num
            XWi = X{t_ii}' * W(:,t_ii);
            XTXWi = X{t_ii}* XWi;
            grad_W = cat(2, grad_W, XTXWi - XY{t_ii});%�õ�RSS���ֵ�ƫ��(�ݶ�)ֵ��X*  X' * w - X * Y
        end
        grad_W = grad_W + rho_L2 * 2 * W;%������RSS���֣���������rho_L2��ֵΪ0
    end

    function [funcVal] = funVal_eval (W)%�õ�RSS���ֵ���ʧ����ֵ
        funcVal = 0;
        for i = 1: task_num
            funcVal = funcVal + 0.5 * norm (Y{i} - X{i}' * W(:, i), 'fro')^2;
        end
        funcVal = funcVal + rho_L2 * norm(W, 'fro')^2;
    end


end