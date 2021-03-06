%% CS294A/CS294W Convolutional Neural Networks Exercise

%  Instructions
%  ------------
% 
%  This file contains code that helps you get started on the
%  convolutional neural networks exercise. In this exercise, you will only
%  need to modify cnnConvolve.m and cnnPool.m. You will not need to modify
%  this file.

%%======================================================================
%% STEP 0: Initialization
%  Here we initialize some parameters used for the exercise.

imageDim = 64;         % image dimension
imageChannels = 3;     % number of channels (rgb, so 3)

patchDim = 8;          % patch dimension
% numPatches = 50000;    % number of patches

visibleSize = patchDim * patchDim * imageChannels;  % number of input units 
outputSize = visibleSize;   % number of output units
hiddenSize = 400;           % number of hidden units 

epsilon = 0.1;	       % epsilon for ZCA whitening

poolDim = 19;          % dimension of pooling region

%%======================================================================
%% STEP 1: Train a sparse autoencoder (with a linear decoder) to learn 



% displayColorNetwork( (W*ZCAWhite)');
load('STL10Features.mat', 'optTheta', 'ZCAWhite', 'meanPatch');
% writeMat(optTheta);
% writeMat(ZCAWhite);
% writeMat(meanPatch);
W = reshape(optTheta(1:visibleSize * hiddenSize), hiddenSize, visibleSize);
b = optTheta(2*hiddenSize*visibleSize+1:2*hiddenSize*visibleSize+hiddenSize);
% displayColorNetwork( (W*ZCAWhite)');

%%======================================================================
%% STEP 3: Convolve and pool with the dataset
%  In this step, you will convolve each of the features you learned with
%  the full large images to obtain the convolved features. You will then
%  pool the convolved features to obtain the pooled features for
%  classification.
%
%  Because the convolved features matrix is very large, we will do the
%  convolution and pooling 50 features at a time to avoid running out of
%  memory. Reduce this number if necessary

    
if (0)
    stepSize = 25;
    assert(mod(hiddenSize, stepSize) == 0, 'stepSize should divide hiddenSize');

    load stlTrainSubset.mat % loads numTrainImages, trainImages, trainLabels
    load stlTestSubset.mat  % loads numTestImages,  testImages,  testLabels

    pooledFeaturesTrain = zeros(hiddenSize, numTrainImages, ...
        floor((imageDim - patchDim + 1) / poolDim), ...
        floor((imageDim - patchDim + 1) / poolDim) );
    pooledFeaturesTest = zeros(hiddenSize, numTestImages, ...
        floor((imageDim - patchDim + 1) / poolDim), ...
        floor((imageDim - patchDim + 1) / poolDim) );

    tic();

    for convPart = 1:(hiddenSize / stepSize)

        featureStart = (convPart - 1) * stepSize + 1;
        featureEnd = convPart * stepSize;

        fprintf('Step %d: features %d to %d\n', convPart, featureStart, featureEnd);  
        Wt = W(featureStart:featureEnd, :);
        bt = b(featureStart:featureEnd);    

        fprintf('Convolving and pooling train images\n');
        convolvedFeaturesThis = cnnConvolve(patchDim, stepSize, ...
            trainImages, Wt, bt, ZCAWhite, meanPatch);
        pooledFeaturesThis = cnnPool(poolDim, convolvedFeaturesThis);
        pooledFeaturesTrain(featureStart:featureEnd, :, :, :) = pooledFeaturesThis;   
        toc();
        clear convolvedFeaturesThis pooledFeaturesThis;

        fprintf('Convolving and pooling test images\n');
        convolvedFeaturesThis = cnnConvolve(patchDim, stepSize, ...
            testImages, Wt, bt, ZCAWhite, meanPatch);
        pooledFeaturesThis = cnnPool(poolDim, convolvedFeaturesThis);
        pooledFeaturesTest(featureStart:featureEnd, :, :, :) = pooledFeaturesThis;   
        toc();

        clear convolvedFeaturesThis pooledFeaturesThis;

    end


    % You might want to save the pooled features since convolution and pooling takes a long time
    save('cnnPooledFeatures.mat', 'pooledFeaturesTrain', 'pooledFeaturesTest');
    toc();
else
    load stlTrainSubset.mat % loads numTrainImages, trainImages, trainLabels
    load stlTestSubset.mat  % loads numTestImages,  testImages,  testLabels
    load('cnnPooledFeatures.mat', 'pooledFeaturesTrain', 'pooledFeaturesTest');
end
%%======================================================================
%% STEP 4: Use pooled features for classification
%  Now, you will use your pooled features to train a softmax classifier,
%  using softmaxTrain from the softmax exercise.
%  Training the softmax classifer for 1000 iterations should take less than
%  10 minutes.

% Add the path to your softmax solution, if necessary
% addpath /path/to/solution/

% Setup parameters for softmax
if (1)
    softmaxLambda = 1e-4;
    numClasses = 4;
    % Reshape the pooledFeatures to form an input vector for softmax
    softmaxX = permute(pooledFeaturesTrain, [1 3 4 2]);
    softmaxX = reshape(softmaxX, numel(pooledFeaturesTrain) / numTrainImages,...
        numTrainImages);
    softmaxY = trainLabels;

    options = struct;
    options.maxIter = 200;
    softmaxModel = softmaxTrain(numel(pooledFeaturesTrain) / numTrainImages,...
        numClasses, softmaxLambda, softmaxX, softmaxY, options);
    save softmaxModel;
else
    load softmaxModel;
end
%%======================================================================
%% STEP 5: Test classifer
%  Now you will test your trained classifer against the test images
tic();
%    featureLength x imageNum x pooledCountX x pooledCountY    (400 x 2000 x 3 x 3)
% -> featureLength x pooledCountX x pooledCountY x imageNum    (400 x 3 x 3 x 2000)
softmaxX = permute(pooledFeaturesTrain, [1 3 4 2]);
softmaxX = reshape(softmaxX, numel(pooledFeaturesTrain) / numTrainImages, numTrainImages);
softmaxY = trainLabels;

[pred] = softmaxPredict(softmaxModel, softmaxX);
acc = (pred(:) == softmaxY(:));
acc = sum(acc) / size(acc, 1);
fprintf('Train Accuracy: %2.3f%%\n', acc * 100);

softmaxX = permute(pooledFeaturesTest, [1 3 4 2]);
softmaxX = reshape(softmaxX, numel(pooledFeaturesTest) / numTestImages, numTestImages);
softmaxY = testLabels;

[pred] = softmaxPredict(softmaxModel, softmaxX);
acc = (pred(:) == softmaxY(:));
acc = sum(acc) / size(acc, 1);
fprintf('Test Accuracy: %2.3f%%\n', acc * 100);
toc();
% You should expect to get an accuracy of around 80% on the test images.
