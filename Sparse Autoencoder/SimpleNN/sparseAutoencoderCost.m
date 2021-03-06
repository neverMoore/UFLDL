function [cost,grad] = sparseAutoencoderCost(theta, visibleSize, hiddenSize, ...
                                             lambda, sparsityParam, beta, data)

elementSize = 10; % length(data); % 100;

% ---------------------------------------
% debugging initilization
% 
visibleSize = 2;   % number of input units 
hiddenSize = 5;     % number of hidden units 
lambda = 0.0001;     % weight decay parameter       
beta = 3;            % weight of sparsity penalty term  
theta = initializeParameters(hiddenSize, visibleSize);
elementSize = 5;

data = zeros(2,elementSize);
for i=1:elementSize
    data(:,i) = [rand(),rand()];
end
%load W1
%load W2
% debugging initilization
% ---------------------------------------


W1 = reshape(theta(1:hiddenSize*visibleSize), hiddenSize, visibleSize);
W2 = reshape(theta(hiddenSize*visibleSize+1:2*hiddenSize*visibleSize), visibleSize, hiddenSize);

b1 = theta(2*hiddenSize*visibleSize+1:2*hiddenSize*visibleSize+hiddenSize);
b2 = theta(2*hiddenSize*visibleSize+hiddenSize+1:end);

% Cost and gradient variables (your code needs to compute these values). 
% Here, we initialize them to zeros. 
a3Temp = zeros(size(data));


learningRate = 0.7;
errorTol = 0.01;

repeat = 0;
for repeat=1:100000
    CostTerm = 0;
    cost = 0;
    W1grad = zeros(size(W1)); 
    W2grad = zeros(size(W2));
    b1grad = zeros(size(b1)); 
    b2grad = zeros(size(b2));
    for elementIndex=1:elementSize

        % forward pass
        for i2=1:hiddenSize    
            a2(i2) = sigmoid(sum(W1(i2,:)' .* data(:,elementIndex)) + b1(i2));
        end

        %A2 = zeros(25,1);
        for i3=1:visibleSize    
            a3(i3) = sigmoid(sum(W2(i3,:) .* a2(1,:)) + b2(i3));
            %D3(i3) = (a3(1,i3) - data(i3,elementIndex))  .* a3(i3) .* (1-a3(i3))
        end

        a3Temp(:,elementIndex) = a3(:);
        % backward propogation

        % delta of level 3  -(y-a3)*f'(z3)
        d3 = (a3(1,:) - data(:,elementIndex)') .* a3(1,:) .* (1-a3(1,:));
        for i2=1:hiddenSize    
            d2(i2) = sum(W2(:,i2)'.*d3(1,:)) .*a2(1,i2).*(1-a2(1,i2));
        end

        % Gradient weight vector cumulation
        W2grad =  W2grad + d3' * a2;
        W1grad = W1grad + d2' * data(:,elementIndex)';
        %W1grad = W1grad + d2' * data(:,elementIndex);

        b1grad = b1grad + d2';
        b2grad = b2grad + d3';


        %elementIndex
        temp = (a3(:) - data(:,elementIndex));

        CostTerm = CostTerm + 0.5 .* norm(temp,2);

    end

    CostTerm = CostTerm / elementSize;

    W2grad = learningRate .* (W2grad ./ elementSize);
    W1grad = learningRate .* (W1grad ./ elementSize);
    %W2grad = learningRate .* (W2grad ./ elementSize + W2 .* lambda );
    %W1grad = learningRate .* (W1grad ./ elementSize + W1 .* lambda );
    b1grad = learningRate .* (b1grad ./ elementSize);
    b2grad = learningRate .* (b2grad ./ elementSize);

    W1 = W1 - W1grad;
    W2 = W2 - W2grad;
    b1 = b1 - b1grad;
    b2 = b2 - b2grad;

    %Error = sqrt(sum(CostTerm))/elementSize;
    %WeightDecay = lambda*(sum(W1(:).*W1(:)) + sum(W2(:).*W2(:)))/2;
    cost = CostTerm; %+ WeightDecay;
    repeat, cost
   
    
    if (cost < errorTol)
        break
    end
end

 
%-------------------------------------------------------------------
% After computing the cost and gradient, we will convert the gradients back
% to a vector format (suitable for minFunc).  Specifically, we will unroll
% your gradient matrices into a vector.

grad = [W1grad(:) ; W2grad(:) ; b1grad(:) ; b2grad(:)];

end

%-------------------------------------------------------------------
% Here's an implementation of the sigmoid function, which you may find useful
% in your computation of the costs and the gradients.  This inputs a (row or
% column) vector (say (z1, z2, z3)) and returns (f(z1), f(z2), f(z3)). 

function sigm = sigmoid(x)
  
    sigm = 1 ./ (1 + exp(-x));
end

