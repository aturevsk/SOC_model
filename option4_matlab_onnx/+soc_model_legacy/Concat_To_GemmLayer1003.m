classdef Concat_To_GemmLayer1003 < nnet.layer.Layer & nnet.layer.Formattable
    % A custom layer auto-generated while importing an ONNX network.

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
        % Specify the path to the class that will be used for codegen
        function name = matlabCodegenRedirect(~)
            name = 'soc_model_legacy.coder.Concat_To_GemmLayer1003';
        end
    end


    methods
        function this = Concat_To_GemmLayer1003(name)
            this.Name = name;
            this.NumInputs = 2;
            this.OutputNames = {'output'};
        end

        function [output] = predict(this, x_lstm_LSTM_output_1, x_lstm_LSTM_1_outp_1)
            if isdlarray(x_lstm_LSTM_output_1)
                x_lstm_LSTM_output_1 = stripdims(x_lstm_LSTM_output_1);
            end
            if isdlarray(x_lstm_LSTM_1_outp_1)
                x_lstm_LSTM_1_outp_1 = stripdims(x_lstm_LSTM_1_outp_1);
            end
            x_lstm_LSTM_output_1NumDims = 3;
            x_lstm_LSTM_1_outp_1NumDims = 3;
            x_lstm_LSTM_output_1 = soc_model_legacy.ops.permuteInputVar(x_lstm_LSTM_output_1, [3 2 1], 3);
            x_lstm_LSTM_1_outp_1 = soc_model_legacy.ops.permuteInputVar(x_lstm_LSTM_1_outp_1, [3 2 1], 3);

            [output, outputNumDims] = Concat_To_GemmGraph1008(this, x_lstm_LSTM_output_1, x_lstm_LSTM_1_outp_1, x_lstm_LSTM_output_1NumDims, x_lstm_LSTM_1_outp_1NumDims, false);
            output = soc_model_legacy.ops.permuteOutputVar(output, ['as-is'], 2);

            output = dlarray(single(output), repmat('U', 1, max(2, outputNumDims)));
        end

        function [output] = forward(this, x_lstm_LSTM_output_1, x_lstm_LSTM_1_outp_1)
            if isdlarray(x_lstm_LSTM_output_1)
                x_lstm_LSTM_output_1 = stripdims(x_lstm_LSTM_output_1);
            end
            if isdlarray(x_lstm_LSTM_1_outp_1)
                x_lstm_LSTM_1_outp_1 = stripdims(x_lstm_LSTM_1_outp_1);
            end
            x_lstm_LSTM_output_1NumDims = 3;
            x_lstm_LSTM_1_outp_1NumDims = 3;
            x_lstm_LSTM_output_1 = soc_model_legacy.ops.permuteInputVar(x_lstm_LSTM_output_1, [3 2 1], 3);
            x_lstm_LSTM_1_outp_1 = soc_model_legacy.ops.permuteInputVar(x_lstm_LSTM_1_outp_1, [3 2 1], 3);

            [output, outputNumDims] = Concat_To_GemmGraph1008(this, x_lstm_LSTM_output_1, x_lstm_LSTM_1_outp_1, x_lstm_LSTM_output_1NumDims, x_lstm_LSTM_1_outp_1NumDims, true);
            output = soc_model_legacy.ops.permuteOutputVar(output, ['as-is'], 2);

            output = dlarray(single(output), repmat('U', 1, max(2, outputNumDims)));
        end

        function [output, outputNumDims1013] = Concat_To_GemmGraph1008(this, x_lstm_LSTM_output_1, x_lstm_LSTM_1_outp_1, x_lstm_LSTM_output_1NumDims, x_lstm_LSTM_1_outp_1NumDims, Training)

            % Execute the operators:
            % Concat:
            [x_lstm_Concat_4_outp, x_lstm_Concat_4_outpNumDims] = soc_model_legacy.ops.onnxConcat(0, {x_lstm_LSTM_output_1, x_lstm_LSTM_1_outp_1}, [x_lstm_LSTM_output_1NumDims, x_lstm_LSTM_1_outp_1NumDims]);

            % Gather:
            [x_Gather_output_0, x_Gather_output_0NumDims] = soc_model_legacy.ops.onnxGather(x_lstm_Concat_4_outp, this.Vars.x_Constant_output_0, 0, x_lstm_Concat_4_outpNumDims, this.NumDims.x_Constant_output_0);

            % Gemm:
            [A, B, C, alpha, beta, x_head_head_0_Gemm_oNumDims] = soc_model_legacy.ops.prepareGemmArgs(x_Gather_output_0, this.head_0_weight, this.head_0_bias, this.Vars.Gemmalpha1009, this.Vars.Gemmbeta1010, 0, 1, this.NumDims.head_0_bias);
            x_head_head_0_Gemm_o = alpha*B*A + beta*C;

            % Relu:
            x_head_head_1_Relu_o = relu(dlarray(x_head_head_0_Gemm_o));
            x_head_head_1_Relu_oNumDims = x_head_head_0_Gemm_oNumDims;

            % Gemm:
            [A, B, C, alpha, beta, outputNumDims] = soc_model_legacy.ops.prepareGemmArgs(x_head_head_1_Relu_o, this.head_2_weight, this.head_2_bias, this.Vars.Gemmalpha1011, this.Vars.Gemmbeta1012, 0, 1, this.NumDims.head_2_bias);
            output = alpha*B*A + beta*C;

            % Set graph output arguments
            outputNumDims1013 = outputNumDims;

        end

    end

end