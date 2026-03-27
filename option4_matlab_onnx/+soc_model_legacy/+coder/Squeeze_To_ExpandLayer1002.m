classdef Squeeze_To_ExpandLayer1002 < nnet.layer.Layer & nnet.layer.Formattable
    % A custom layer auto-generated while importing an ONNX network.
    %#codegen

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
        % Specify the properties of the class that will not be modified
        % after the first assignment.
        function p = matlabCodegenNontunableProperties(~)
            p = {
                % Constants, i.e., Vars, NumDims and all learnables and states
                'Vars'
                'NumDims'
                'x_lstm_Constant_7_ou'
                'x_lstm_Constant_8_ou'
                };
        end
    end


    methods(Static, Hidden)
        % Instantiate a codegenable layer instance from a MATLAB layer instance
        function this_cg = matlabCodegenToRedirected(mlInstance)
            this_cg = soc_model_legacy.coder.Squeeze_To_ExpandLayer1002(mlInstance);
        end
        function this_ml = matlabCodegenFromRedirected(cgInstance)
            this_ml = soc_model_legacy.Squeeze_To_ExpandLayer1002(cgInstance.Name);
            if isstruct(cgInstance.Vars)
                names = fieldnames(cgInstance.Vars);
                for i=1:numel(names)
                    fieldname = names{i};
                    this_ml.Vars.(fieldname) = dlarray(cgInstance.Vars.(fieldname));
                end
            else
                this_ml.Vars = [];
            end
            this_ml.NumDims = cgInstance.NumDims;
            this_ml.x_lstm_Constant_7_ou = cgInstance.x_lstm_Constant_7_ou;
            this_ml.x_lstm_Constant_8_ou = cgInstance.x_lstm_Constant_8_ou;
        end
    end

    methods
        function this = Squeeze_To_ExpandLayer1002(mlInstance)
            this.Name = mlInstance.Name;
            this.NumOutputs = 3;
            this.OutputNames = {'x_lstm_Squeeze_outpu', 'x_lstm_Expand_2_outp', 'x_lstm_Expand_3_outp'};
            if isstruct(mlInstance.Vars)
                names = fieldnames(mlInstance.Vars);
                for i=1:numel(names)
                    fieldname = names{i};
                    this.Vars.(fieldname) = soc_model_legacy.coder.ops.extractIfDlarray(mlInstance.Vars.(fieldname));
                end
            else
                this.Vars = [];
            end

            this.NumDims = mlInstance.NumDims;
            this.x_lstm_Constant_7_ou = mlInstance.x_lstm_Constant_7_ou;
            this.x_lstm_Constant_8_ou = mlInstance.x_lstm_Constant_8_ou;
        end

        function [x_lstm_Squeeze_outpu, x_lstm_Expand_2_outp, x_lstm_Expand_3_outp] = predict(this, x_lstm_LSTM_output_0__)
            if isdlarray(x_lstm_LSTM_output_0__)
                x_lstm_LSTM_output_0_ = stripdims(x_lstm_LSTM_output_0__);
            else
                x_lstm_LSTM_output_0_ = x_lstm_LSTM_output_0__;
            end
            x_lstm_LSTM_output_0NumDims = 4;
            x_lstm_LSTM_output_0 = soc_model_legacy.coder.ops.permuteInputVar(x_lstm_LSTM_output_0_, [3 4 2 1], 4);

            [x_lstm_Squeeze_outpu__, x_lstm_Expand_2_outp__, x_lstm_Expand_3_outp__, x_lstm_Squeeze_outpuNumDims__, x_lstm_Expand_2_outpNumDims__, x_lstm_Expand_3_outpNumDims__] = Squeeze_To_ExpandGraph1004(this, x_lstm_LSTM_output_0, x_lstm_LSTM_output_0NumDims, false);
            x_lstm_Squeeze_outpu_ = soc_model_legacy.coder.ops.permuteOutputVar(x_lstm_Squeeze_outpu__, [3 2 1], 3);
            x_lstm_Expand_2_outp_ = soc_model_legacy.coder.ops.permuteOutputVar(x_lstm_Expand_2_outp__, [3 2 1], 3);
            x_lstm_Expand_3_outp_ = soc_model_legacy.coder.ops.permuteOutputVar(x_lstm_Expand_3_outp__, [3 2 1], 3);

            x_lstm_Squeeze_outpu = dlarray(single(x_lstm_Squeeze_outpu_), 'CBT');
            x_lstm_Expand_2_outp = dlarray(single(x_lstm_Expand_2_outp_), 'CB');
            x_lstm_Expand_3_outp = dlarray(single(x_lstm_Expand_3_outp_), 'CB');
        end

        function [x_lstm_Squeeze_outpu, x_lstm_Expand_2_outp, x_lstm_Expand_3_outp, x_lstm_Squeeze_outpuNumDims1005, x_lstm_Expand_2_outpNumDims1006, x_lstm_Expand_3_outpNumDims1007] = Squeeze_To_ExpandGraph1004(this, x_lstm_LSTM_output_0, x_lstm_LSTM_output_0NumDims, Training)

            % Execute the operators:
            % Squeeze:
            [x_lstm_Squeeze_outpu, x_lstm_Squeeze_outpuNumDims] = soc_model_legacy.coder.ops.onnxSqueeze(x_lstm_LSTM_output_0, this.Vars.x_lstm_Constant_6_ou, coder.const(x_lstm_LSTM_output_0NumDims));

            % Shape:
            [x_lstm_Shape_2_outpu, x_lstm_Shape_2_outpuNumDims] = soc_model_legacy.coder.ops.onnxShape(x_lstm_Squeeze_outpu, coder.const(x_lstm_Squeeze_outpuNumDims), 0, coder.const(x_lstm_Squeeze_outpuNumDims)+1);

            % Gather:
            [x_lstm_Gather_2_outp, x_lstm_Gather_2_outpNumDims] = soc_model_legacy.coder.ops.onnxGather(x_lstm_Shape_2_outpu, this.Vars.x_lstm_Constant_9_ou, 0, coder.const(x_lstm_Shape_2_outpuNumDims), this.NumDims.x_lstm_Constant_9_ou);

            % Unsqueeze:
            [shape1004, onnx__Concat_181NumDims] = soc_model_legacy.coder.ops.prepareUnsqueezeArgs(x_lstm_Gather_2_outp, this.Vars.onnx__Unsqueeze_180, coder.const(x_lstm_Gather_2_outpNumDims));
            onnx__Concat_181 = reshape(x_lstm_Gather_2_outp, shape1004);

            % Concat:
            [x_lstm_Concat_2_outp, x_lstm_Concat_2_outpNumDims] = soc_model_legacy.coder.ops.onnxConcat(0, {this.Vars.onnx__Concat_254, onnx__Concat_181, this.Vars.x_lstm_Constant_10_o}, [this.NumDims.onnx__Concat_254, coder.const(onnx__Concat_181NumDims), this.NumDims.x_lstm_Constant_10_o]);

            % Expand:
            [shape1005, x_lstm_Expand_2_outpNumDims] = soc_model_legacy.coder.ops.prepareExpandArgs(this.NumDims.x_lstm_Constant_7_ou, x_lstm_Concat_2_outp);
            x_lstm_Expand_2_outp = this.x_lstm_Constant_7_ou + zeros(shape1005);

            % Shape:
            [x_lstm_Shape_3_outpu, x_lstm_Shape_3_outpuNumDims] = soc_model_legacy.coder.ops.onnxShape(x_lstm_Squeeze_outpu, coder.const(x_lstm_Squeeze_outpuNumDims), 0, coder.const(x_lstm_Squeeze_outpuNumDims)+1);

            % Gather:
            [x_lstm_Gather_3_outp, x_lstm_Gather_3_outpNumDims] = soc_model_legacy.coder.ops.onnxGather(x_lstm_Shape_3_outpu, this.Vars.x_lstm_Constant_11_o, 0, coder.const(x_lstm_Shape_3_outpuNumDims), this.NumDims.x_lstm_Constant_11_o);

            % Unsqueeze:
            [shape1006, onnx__Concat_192NumDims] = soc_model_legacy.coder.ops.prepareUnsqueezeArgs(x_lstm_Gather_3_outp, this.Vars.onnx__Unsqueeze_191, coder.const(x_lstm_Gather_3_outpNumDims));
            onnx__Concat_192 = reshape(x_lstm_Gather_3_outp, shape1006);

            % Concat:
            [x_lstm_Concat_3_outp, x_lstm_Concat_3_outpNumDims] = soc_model_legacy.coder.ops.onnxConcat(0, {this.Vars.onnx__Concat_255, onnx__Concat_192, this.Vars.x_lstm_Constant_12_o}, [this.NumDims.onnx__Concat_255, coder.const(onnx__Concat_192NumDims), this.NumDims.x_lstm_Constant_12_o]);

            % Expand:
            [shape1007, x_lstm_Expand_3_outpNumDims] = soc_model_legacy.coder.ops.prepareExpandArgs(this.NumDims.x_lstm_Constant_8_ou, x_lstm_Concat_3_outp);
            x_lstm_Expand_3_outp = this.x_lstm_Constant_8_ou + zeros(shape1007);

            % Set graph output arguments
            x_lstm_Squeeze_outpuNumDims1005 = coder.const(x_lstm_Squeeze_outpuNumDims);
            x_lstm_Expand_2_outpNumDims1006 = coder.const(x_lstm_Expand_2_outpNumDims);
            x_lstm_Expand_3_outpNumDims1007 = coder.const(x_lstm_Expand_3_outpNumDims);

        end

    end

end