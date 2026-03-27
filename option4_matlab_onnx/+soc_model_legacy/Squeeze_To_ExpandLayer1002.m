classdef Squeeze_To_ExpandLayer1002 < nnet.layer.Layer & nnet.layer.Formattable
    % A custom layer auto-generated while importing an ONNX network.

    %#ok<*PROPLC>
    %#ok<*NBRAK>
    %#ok<*INUSL>
    %#ok<*VARARG>
    properties (Learnable)
        x_lstm_Constant_7_ou
        x_lstm_Constant_8_ou
    end

    properties (State)
    end

    properties
        Vars
        NumDims
    end


    methods(Static, Hidden)
        % Specify the path to the class that will be used for codegen
        function name = matlabCodegenRedirect(~)
            name = 'soc_model_legacy.coder.Squeeze_To_ExpandLayer1002';
        end
    end


    methods
        function this = Squeeze_To_ExpandLayer1002(name)
            this.Name = name;
            this.NumOutputs = 3;
            this.OutputNames = {'x_lstm_Squeeze_outpu', 'x_lstm_Expand_2_outp', 'x_lstm_Expand_3_outp'};
        end

        function [x_lstm_Squeeze_outpu, x_lstm_Expand_2_outp, x_lstm_Expand_3_outp] = predict(this, x_lstm_LSTM_output_0)
            if isdlarray(x_lstm_LSTM_output_0)
                x_lstm_LSTM_output_0 = stripdims(x_lstm_LSTM_output_0);
            end
            x_lstm_LSTM_output_0NumDims = 4;
            x_lstm_LSTM_output_0 = soc_model_legacy.ops.permuteInputVar(x_lstm_LSTM_output_0, [3 4 2 1], 4);

            [x_lstm_Squeeze_outpu, x_lstm_Expand_2_outp, x_lstm_Expand_3_outp, x_lstm_Squeeze_outpuNumDims, x_lstm_Expand_2_outpNumDims, x_lstm_Expand_3_outpNumDims] = Squeeze_To_ExpandGraph1004(this, x_lstm_LSTM_output_0, x_lstm_LSTM_output_0NumDims, false);
            x_lstm_Squeeze_outpu = soc_model_legacy.ops.permuteOutputVar(x_lstm_Squeeze_outpu, [3 2 1], 3);
            x_lstm_Expand_2_outp = soc_model_legacy.ops.permuteOutputVar(x_lstm_Expand_2_outp, [3 2 1], 3);
            x_lstm_Expand_3_outp = soc_model_legacy.ops.permuteOutputVar(x_lstm_Expand_3_outp, [3 2 1], 3);

            x_lstm_Squeeze_outpu = dlarray(single(x_lstm_Squeeze_outpu), 'CBT');
            x_lstm_Expand_2_outp = dlarray(single(x_lstm_Expand_2_outp), 'CB');
            x_lstm_Expand_3_outp = dlarray(single(x_lstm_Expand_3_outp), 'CB');
        end

        function [x_lstm_Squeeze_outpu, x_lstm_Expand_2_outp, x_lstm_Expand_3_outp] = forward(this, x_lstm_LSTM_output_0)
            if isdlarray(x_lstm_LSTM_output_0)
                x_lstm_LSTM_output_0 = stripdims(x_lstm_LSTM_output_0);
            end
            x_lstm_LSTM_output_0NumDims = 4;
            x_lstm_LSTM_output_0 = soc_model_legacy.ops.permuteInputVar(x_lstm_LSTM_output_0, [3 4 2 1], 4);

            [x_lstm_Squeeze_outpu, x_lstm_Expand_2_outp, x_lstm_Expand_3_outp, x_lstm_Squeeze_outpuNumDims, x_lstm_Expand_2_outpNumDims, x_lstm_Expand_3_outpNumDims] = Squeeze_To_ExpandGraph1004(this, x_lstm_LSTM_output_0, x_lstm_LSTM_output_0NumDims, true);
            x_lstm_Squeeze_outpu = soc_model_legacy.ops.permuteOutputVar(x_lstm_Squeeze_outpu, [3 2 1], 3);
            x_lstm_Expand_2_outp = soc_model_legacy.ops.permuteOutputVar(x_lstm_Expand_2_outp, [3 2 1], 3);
            x_lstm_Expand_3_outp = soc_model_legacy.ops.permuteOutputVar(x_lstm_Expand_3_outp, [3 2 1], 3);

            x_lstm_Squeeze_outpu = dlarray(single(x_lstm_Squeeze_outpu), 'CBT');
            x_lstm_Expand_2_outp = dlarray(single(x_lstm_Expand_2_outp), 'CB');
            x_lstm_Expand_3_outp = dlarray(single(x_lstm_Expand_3_outp), 'CB');
        end

        function [x_lstm_Squeeze_outpu, x_lstm_Expand_2_outp, x_lstm_Expand_3_outp, x_lstm_Squeeze_outpuNumDims1005, x_lstm_Expand_2_outpNumDims1006, x_lstm_Expand_3_outpNumDims1007] = Squeeze_To_ExpandGraph1004(this, x_lstm_LSTM_output_0, x_lstm_LSTM_output_0NumDims, Training)

            % Execute the operators:
            % Squeeze:
            [x_lstm_Squeeze_outpu, x_lstm_Squeeze_outpuNumDims] = soc_model_legacy.ops.onnxSqueeze(x_lstm_LSTM_output_0, this.Vars.x_lstm_Constant_6_ou, x_lstm_LSTM_output_0NumDims);

            % Shape:
            [x_lstm_Shape_2_outpu, x_lstm_Shape_2_outpuNumDims] = soc_model_legacy.ops.onnxShape(x_lstm_Squeeze_outpu, x_lstm_Squeeze_outpuNumDims, 0, x_lstm_Squeeze_outpuNumDims+1);

            % Gather:
            [x_lstm_Gather_2_outp, x_lstm_Gather_2_outpNumDims] = soc_model_legacy.ops.onnxGather(x_lstm_Shape_2_outpu, this.Vars.x_lstm_Constant_9_ou, 0, x_lstm_Shape_2_outpuNumDims, this.NumDims.x_lstm_Constant_9_ou);

            % Unsqueeze:
            [shape, onnx__Concat_181NumDims] = soc_model_legacy.ops.prepareUnsqueezeArgs(x_lstm_Gather_2_outp, this.Vars.onnx__Unsqueeze_180, x_lstm_Gather_2_outpNumDims);
            onnx__Concat_181 = reshape(x_lstm_Gather_2_outp, shape);

            % Concat:
            [x_lstm_Concat_2_outp, x_lstm_Concat_2_outpNumDims] = soc_model_legacy.ops.onnxConcat(0, {this.Vars.onnx__Concat_254, onnx__Concat_181, this.Vars.x_lstm_Constant_10_o}, [this.NumDims.onnx__Concat_254, onnx__Concat_181NumDims, this.NumDims.x_lstm_Constant_10_o]);

            % Expand:
            [shape, x_lstm_Expand_2_outpNumDims] = soc_model_legacy.ops.prepareExpandArgs(this.NumDims.x_lstm_Constant_7_ou, x_lstm_Concat_2_outp);
            x_lstm_Expand_2_outp = this.x_lstm_Constant_7_ou + zeros(shape);

            % Shape:
            [x_lstm_Shape_3_outpu, x_lstm_Shape_3_outpuNumDims] = soc_model_legacy.ops.onnxShape(x_lstm_Squeeze_outpu, x_lstm_Squeeze_outpuNumDims, 0, x_lstm_Squeeze_outpuNumDims+1);

            % Gather:
            [x_lstm_Gather_3_outp, x_lstm_Gather_3_outpNumDims] = soc_model_legacy.ops.onnxGather(x_lstm_Shape_3_outpu, this.Vars.x_lstm_Constant_11_o, 0, x_lstm_Shape_3_outpuNumDims, this.NumDims.x_lstm_Constant_11_o);

            % Unsqueeze:
            [shape, onnx__Concat_192NumDims] = soc_model_legacy.ops.prepareUnsqueezeArgs(x_lstm_Gather_3_outp, this.Vars.onnx__Unsqueeze_191, x_lstm_Gather_3_outpNumDims);
            onnx__Concat_192 = reshape(x_lstm_Gather_3_outp, shape);

            % Concat:
            [x_lstm_Concat_3_outp, x_lstm_Concat_3_outpNumDims] = soc_model_legacy.ops.onnxConcat(0, {this.Vars.onnx__Concat_255, onnx__Concat_192, this.Vars.x_lstm_Constant_12_o}, [this.NumDims.onnx__Concat_255, onnx__Concat_192NumDims, this.NumDims.x_lstm_Constant_12_o]);

            % Expand:
            [shape, x_lstm_Expand_3_outpNumDims] = soc_model_legacy.ops.prepareExpandArgs(this.NumDims.x_lstm_Constant_8_ou, x_lstm_Concat_3_outp);
            x_lstm_Expand_3_outp = this.x_lstm_Constant_8_ou + zeros(shape);

            % Set graph output arguments
            x_lstm_Squeeze_outpuNumDims1005 = x_lstm_Squeeze_outpuNumDims;
            x_lstm_Expand_2_outpNumDims1006 = x_lstm_Expand_2_outpNumDims;
            x_lstm_Expand_3_outpNumDims1007 = x_lstm_Expand_3_outpNumDims;

        end

    end

end