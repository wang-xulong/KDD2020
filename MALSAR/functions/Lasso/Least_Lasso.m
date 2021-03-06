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
%% LICENSE
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%   Copyright (C) 2011 - 2012 Jiayu Zhou and Jieping Ye
%
%   You are suggested to first read the Manual.
%   For any problem, please contact with Jiayu Zhou via jiayu.zhou@asu.edu
%
%   Last modified on June 3, 2012.
%
%% Related papers
%
%   [1] Tibshirani, J. Regression shrinkage and selection via
%   the Lasso, Journal of the Royal Statistical Society. Series B 1996
%
%% Related functions
%   Logistic_Lasso, init_opts

%% Code starts here
%w is the matrix weight

%funcVal is the function value of the last iteration of this model
%rho1 regularizaion parameter
%opts?????????????
function [W, funcVal] = Least_Lasso(X, Y, rho1, opts)

if nargin <3
    error('\n Inputs: X, Y, abd rho1 should be specified!\n');
end
% cell X array transpose ;every cell is n x d; when tansposed:
% row:feature number (d)
%column:sample number (n)
X = multi_transpose(X);

if nargin <4
    opts = [];
end

% initialize options.
opts=init_opts(opts);

if isfield(opts, 'rho_L2')
    rho_L2 = opts.rho_L2;
else
    rho_L2 = 0;
end

% X contains many matrix(n x d)?the number of task number is length(X)
task_num  = length (X);
%every cell's demension is d
dimension = size(X{1}, 1);
%store function value
funcVal = [];

%create cell to store result in every task
XY = cell(task_num, 1);
%
W0_prep = [];

% initialize a weight
%every XY{t_idx} is the result of every task(dxn  x   nx1)
%put the result of every task(dxn  x   nx1) into W0_prep
for t_idx = 1: task_num
    XY{t_idx} = X{t_idx}*Y{t_idx};
    W0_prep = cat(2, W0_prep, XY{t_idx});
end

% initialize a starting point
if opts.init==2
    W0 = zeros(dimension, task_num);
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


bFlag=0; % this flag tests whether the gradient step only changes a little

Wz= W0;
Wz_old = W0;

t = 1;
t_old = 0;


iter = 0;
gamma = 1;
gamma_inc = 2;

while iter < opts.maxIter
    %regularizaion parameter
    alpha = (t_old - 1) /t;
    
    Ws = (1 + alpha) * Wz - alpha * Wz_old;
    
    % compute function value and gradients of the search point
    gWs  = gradVal_eval(Ws);
    Fs   = funVal_eval  (Ws);
    
    while true
        [Wzp, l1c_wzp] = l1_projection(Ws - gWs/gamma, 2 * rho1 / gamma);
        Fzp = funVal_eval  (Wzp);
        
        delta_Wzp = Wzp - Ws;
        r_sum = norm(delta_Wzp, 'fro')^2;
        Fzp_gamma = Fs + sum(sum(delta_Wzp .* gWs)) + gamma/2 * sum(sum(delta_Wzp.*delta_Wzp));
        
        if (r_sum <=1e-20)
            bFlag=1; % this shows that, the gradient step makes little improvement
            break;
        end
        
        if (Fzp <= Fzp_gamma)
            break;
        else
            gamma = gamma * gamma_inc;
        end
    end
    
    Wz_old = Wz;
    Wz = Wzp;
    
    funcVal = cat(1, funcVal, Fzp + rho1 * l1c_wzp);
    
    if (bFlag)
        % fprintf('\n The program terminates as the gradient step changes the solution very small.');
        break;
    end
    
    % test stop condition.
    switch(opts.tFlag)
        case 0
            if iter>=2
                if (abs( funcVal(end) - funcVal(end-1) ) <= opts.tol)
                    break;
                end
            end
        case 1
            if iter>=2
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
    
    iter = iter + 1;
    t_old = t;
    t = 0.5 * (1 + (1+ 4 * t^2)^0.5);
    
end

W = Wzp;


% private functions

    function [z, l1_comp_val] = l1_projection (v, beta)
        % this projection calculates
        % argmin_z = \|z-v\|_2^2 + beta \|z\|_1
        % z: solution
        % l1_comp_val: value of l1 component (\|z\|_1)
        z = sign(v).*max(0,abs(v)- beta/2);
         
        l1_comp_val = sum(sum(abs(z)));
        %l1_comp_val = max(sum(abs(z)));
    end

    function [grad_W] = gradVal_eval(W)
        grad_W = [];
        for t_ii = 1:task_num
            XWi = X{t_ii}' * W(:,t_ii);
            XTXWi = X{t_ii}* XWi;
            grad_W = cat(2, grad_W, XTXWi - XY{t_ii});
        end
        grad_W = grad_W + rho_L2 * 2 * W;
    end

    function [funcVal] = funVal_eval (W)
        funcVal = 0;
        for i = 1: task_num
            funcVal = funcVal + 0.5 * norm (Y{i} - X{i}' * W(:, i), 'fro')^2;
        end
        funcVal = funcVal + rho_L2 * norm(W, 'fro')^2;
    end


end