classdef Concat_To_GemmLayer1003 < nnet.layer.Layer & nnet.layer.Formattable
    % A custom layer auto-generated while importing an ONNX network.
    %#codegen

    %#ok<*PROPLC>
    %#ok<*NBRAK>
    %#ok<*INUSL>
    %#ok<*VARARG>
    properties (Learnable)
        head_0_weight
        head_0_bias
        head_2_weight
        head_2_bias
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
                'head_0_weight'
                'head_0_bias'
                'head_2_weight'
                'head_2_bias'
                };
        end
    end


    methods(Static, Hidden)
        % Instantiate a codegenable layer instance from a MATLAB layer instance
        function this_cg = matlabCodegenToRedirected(mlInstance)
            this_cg = soc_model_legacy.coder.Concat_To_GemmLayer1003(mlInstance);
        end
        function this_ml = matlabCodegenFromRedirected(cgInstance)
            this_ml = soc_model_legacy.Concat_To_GemmLayer1003(cgInstance.Name);
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
            this_ml.head_0_weight = cgInstance.head_0_weight;
            this_ml.head_0_bias = cgInstance.head_0_bias;
            this_ml.head_2_weight = cgInstance.head_2_weight;
            this_ml.head_2_bias = cgInstance.head_2_bias;
        end
    end

    methods
        function this = Concat_To_GemmLayer1003(mlInstance)
            this.Name = mlInstance.Name;
            this.NumInputs = 2;
            this.OutputNames = {'output'};
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
            this.head_0_weight = mlInstance.head_0_weight;
            this.head_0_bias = mlInstance.head_0_bias;
            this.head_2_weight = mlInstance.head_2_weight;
            this.head_2_bias = mlInstance.head_2_bias;
        end

        function [output] = predict(this, x_lstm_LSTM_output_1__, x_lstm_LSTM_1_outp_1__)
            if isdlarray(x_lstm_LSTM_output_1__)
                x_lstm_LSTM_output_1_ = stripdims(x_lstm_LSTM_output_1__);
            else
                x_lstm_LSTM_output_1_ = x_lstm_LSTM_output_1__;
            end
            if isdlarray(x_lstm_LSTM_1_outp_1__)
                x_lstm_LSTM_1_outp_1_ = stripdims(x_lstm_LSTM_1_outp_1__);
            else
                x_lstm_LSTM_1_outp_1_ = x_lstm_LSTM_1_outp_1__;
            end
            x_lstm_LSTM_output_1NumDims = 3;
            x_lstm_LSTM_1_outp_1NumDims = 3;
            x_lstm_LSTM_output_1 = soc_model_legacy.coder.ops.permuteInputVar(x_lstm_LSTM_output_1_, [3 2 1], 3);
            x_lstm_LSTM_1_outp_1 = soc_model_legacy.coder.ops.permuteInputVar(x_lstm_LSTM_1_outp_1_, [3 2 1], 3);

            [output__, outputNumDims__] = Concat_To_GemmGraph1008(this, x_lstm_LSTM_output_1, x_lstm_LSTM_1_outp_1, x_lstm_LSTM_output_1NumDims, x_lstm_LSTM_1_outp_1NumDims, false);
            output_ = soc_model_legacy.coder.ops.permuteOutputVar(output__, ['as-is'], 2);

            output = dlarray(single(output_), repmat('U', 1, max(2, coder.const(outputNumDims__))));
        end

        function [output, outputNumDims1013] = Concat_To_GemmGraph1008(this, x_lstm_LSTM_output_1, x_lstm_LSTM_1_outp_1, x_lstm_LSTM_output_1NumDims, x_lstm_LSTM_1_outp_1NumDims, Training)

            % Execute the operators:
            % Concat:
            [x_lstm_Concat_4_outp, x_lstm_Concat_4_outpNumDims] = soc_model_legacy.coder.ops.onnxConcat(0, {x_lstm_LSTM_output_1, x_lstm_LSTM_1_outp_1}, [coder.const(x_lstm_LSTM_output_1NumDims), coder.const(x_lstm_LSTM_1_outp_1NumDims)]);

            % Gather:
            [x_Gather_output_0, x_Gather_output_0NumDims] = soc_model_legacy.coder.ops.onnxGather(x_lstm_Concat_4_outp, this.Vars.x_Constant_output_0, 0, coder.const(x_lstm_Concat_4_outpNumDims), this.NumDims.x_Constant_output_0);

            % Gemm:
            [A1008, B1009, C1010, alpha1011, beta1012, x_head_head_0_Gemm_oNumDims] = soc_model_legacy.coder.ops.prepareGemmArgs(x_Gather_output_0, this.head_0_weight, this.head_0_bias, this.Vars.Gemmalpha1009, this.Vars.Gemmbeta1010, 0, 1, this.NumDims.head_0_bias);
            x_head_head_0_Gemm_o = alpha1011*B1009*A1008 + beta1012*C1010;

            % Relu:
            X1013 = dlarray(soc_model_legacy.coder.ops.extractIfDlarray(x_head_head_0_Gemm_o));
            Y1014 = relu(X1013);
            x_head_head_1_Relu_o = soc_model_legacy.coder.ops.extractIfDlarray(Y1014);
            x_head_head_1_Relu_oNumDims = coder.const(x_head_head_0_Gemm_oNumDims);

            % Gemm:
            [A1015, B1016, C1017, alpha1018, beta1019, outputNumDims] = soc_model_legacy.coder.ops.prepareGemmArgs(x_head_head_1_Relu_o, this.head_2_weight, this.head_2_bias, this.Vars.Gemmalpha1011, this.Vars.Gemmbeta1012, 0, 1, this.NumDims.head_2_bias);
            output = alpha1018*B1016*A1015 + beta1019*C1017;

            % Set graph output arguments
            outputNumDims1013 = coder.const(outputNumDims);

        end

    end

end