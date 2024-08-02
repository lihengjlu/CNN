
%输入数据
load('TrainCNNDataRectangle.mat', 'TrainingIm', 'TrainingData', 'ValidationData', 'ValidationIm');

%通过添加旋转图像来增强数据
TrainingIm = cat(4, TrainingIm, turn(TrainingIm, -pi / 2));
TrainingData = cat(1, TrainingData(:, 1), TrainingData(:, 4));

% 限制数据集的值范围
indexTraining = (TrainingData(1:end, 1) < 1 & TrainingData(1:end, 1) > 10^(-3));
indexValidation = (ValidationData(1:end, 1) < 1 & ValidationData(1:end, 1) > 10^(-3));
TrainingImRestr = (TrainingIm(:, :, 1, indexTraining));
TrainingDataRestr = (TrainingData(indexTraining, 1));

% 通过定义层结构构建神经网络

layers = [; ...
    imageInputLayer([64, 64, 1]); ...
    convolution2dLayer([3, 3], 20, 'Padding', 'same', 'Name', 'conv'); ...
    reluLayer; ...
    batchNormalizationLayer; ...
    maxPooling2dLayer(2, 'Stride', 2); ...
    convolution2dLayer([2, 2], 40, 'Padding', 'same'); ...
    reluLayer; ...
    batchNormalizationLayer; ...
    maxPooling2dLayer(2, 'Stride', 2); ...
    convolution2dLayer([2, 2], 80, 'Padding', 'same'); ...
    reluLayer; ...
    batchNormalizationLayer; ...
    convolution2dLayer([2, 2], 160, 'Padding', 'same'); ...
    reluLayer; ...
    batchNormalizationLayer; ...
    maxPooling2dLayer(2, 'Stride', 2); ...
    convolution2dLayer([2, 2], 320, 'Padding', 'same'); ...
    reluLayer; ...
    batchNormalizationLayer; ...
    fullyConnectedLayer(15); ...
    tanhLayer; ...
    fullyConnectedLayer(1); ...
    regressionLayer];


% 设置训练参数
miniBatchSize = 250;
opts = trainingOptions('adam', ...
    'GradientDecayFactor', .9, ...
    'MaxEpochs', 50, ...
    'InitialLearnRate', 0.005, ...
    'MiniBatchSize', miniBatchSize, ...
    'LearnRateSchedule', 'piecewise', ...
    'LearnRateDropFactor', 0.8, ...
    'LearnRateDropPeriod', 10, ...
    'ValidationFrequency', 50, ...
    'ExecutionEnvironment', 'gpu', ...
    'Shuffle', 'every-epoch', ...
    'Plots', 'training-progress', ...
    'Verbose', true, 'ValidationData', {ValidationIm(:, :, 1, indexValidation), 0.9 + (0.1 * log(ValidationData(indexValidation, 1)))});
net = trainNetwork(single(TrainingImRestr), 0.9+0.1*log(TrainingDataRestr), layers, opts);

%% 评估训练效果

% 计算决定系数
predicted11 = exp(10*(net.predict(ValidationIm(:, :, 1, indexValidation)) - 0.9));
val11 = ValidationData(indexValidation, 1);
Rsquare11 = 1 - sum((log10(predicted11)-real(log10(val11))).^2) / (sum((log10(val11)-mean(log10(val11))).^2))

predicted22 = exp(10*(net.predict(turn(ValidationIm(:, :, 1, indexValidation), pi/2)) - 0.9));
val22 = ValidationData(indexValidation, 1);
Rsquare22 = 1 - sum((log10(predicted22)-real(log10(val22))).^2) / (sum((log10(val22)-mean(log10(val22))).^2))
% 绘制相关图
plot(log10(val11), log10(predicted11), '.');
hold on
plot(log10(val11), log10(val11), 'LineWidth', 2);
xlabel('log(K_{1,1}) 验证');
ylabel('log(K_{1,1}) 预测');
set(gca, 'FontSize', 14);
