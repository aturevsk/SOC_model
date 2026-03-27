classdef Shape_To_ExpandLayer1000 < nnet.layer.Layer & nnet.layer.Formattable
    % A custom layer auto-generated while importing an ONNX network.
    %#codegen

    %#ok<*PROPLC>
    %#ok<*NBRAK>
    %#ok<*INUSL>
    %#ok<*VARARG>
    properties (Learnable)
        x_lstm_Constant_1_ou
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
                'x_lstm_Constant_1_ou'
                };
        end
    end


    methods(Static, Hidden)
        % Instantiate a codegenable layer instance from a MATLAB layer instance
        function this_cg = matlabCodegenToRedirected(mlInstance)
            this_cg = soc_model_legacy.coder.Shape_To_ExpandLayer1000(mlInstance);
        end
        function this_ml = matlabCodegenFromRedirected(cgInstance)
            this_ml = soc_model_legacy.Shape_To_ExpandLayer1000(cgInstance.Name);
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
            this_ml.x_lstm_Constant_1_ou = cgInstance.x_lstm_Constant_1_ou;
        end
    end

    methods
        function this = Shape_To_ExpandLayer1000(mlInstance)
            this.Name = mlInstance.Name;
            this.OutputNames = {'x_lstm_Expand_1_outp'};
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
            this.x_lstm_Constant_1_ou = mlInstance.x_lstm_Constant_1_ou;
        end

        function [x_lstm_Expand_1_outp] = predict(this, x_lstm_Transpose_out__)
            if isdlarray(x_lstm_Transpose_out__)
                x_lstm_Transpose_out_ = stripdims(x_lstm_Transpose_out__);
            else
                x_lstm_Transpose_out_ = x_lstm_Transpose_out__;
            end
            x_lstm_Transpose_outNumDims = 3;
            x_lstm_Transpose_out = soc_model_legacy.coder.ops.permuteInputVar(x_lstm_Transpose_out_, [3 2 1], 3);

            [x_lstm_Expand_1_outp__, x_lstm_Expand_1_outpNumDims__] = Shape_To_ExpandGraph1000(this, x_lstm_Transpose_out, x_lstm_Transpose_outNumDims, false);
            x_lstm_Expand_1_outp_ = soc_model_legacy.coder.ops.permuteOutputVar(x_lstm_Expand_1_outp__, [3 2 1], 3);

            x_lstm_Expand_1_outp = dlarray(single(x_lstm_Expand_1_outp_), 'CB');
        end

        function [x_lstm_Expand_1_outp, x_lstm_Expand_1_outpNumDims1001] = Shape_To_ExpandGraph1000(this, x_lstm_Transpose_out, x_lstm_Transpose_outNumDims, Training)

            % Execute the operators:
            % Shape:
            [x_lstm_Shape_1_outpu, x_lstm_Shape_1_outpuNumDims] = soc_model_legacy.coder.ops.onnxShape(x_lstm_Transpose_out, coder.const(x_lstm_Transpose_outNumDims), 0, coder.const(x_lstm_Transpose_outNumDims)+1);

            % Gather:
            [x_lstm_Gather_1_outp, x_lstm_Gather_1_outpNumDims] = soc_model_legacy.coder.ops.onnxGather(x_lstm_Shape_1_outpu, this.Vars.x_lstm_Constant_4_ou, 0, coder.const(x_lstm_Shape_1_outpuNumDims), this.NumDims.x_lstm_Constant_4_ou);

            % Unsqueeze:
            [shape1000, onnx__Concat_98NumDims] = soc_model_legacy.coder.ops.prepareUnsqueezeArgs(x_lstm_Gather_1_outp, this.Vars.onnx__Unsqueeze_97, coder.const(x_lstm_Gather_1_outpNumDims));
            onnx__Concat_98 = reshape(x_lstm_Gather_1_outp, shape1000);

            % Concat:
            [x_lstm_Concat_1_outp, x_lstm_Concat_1_outpNumDims] = soc_model_legacy.coder.ops.onnxConcat(0, {this.Vars.onnx__Concat_231, onnx__Concat_98, this.Vars.x_lstm_Constant_5_ou}, [this.NumDims.onnx__Concat_231, coder.const(onnx__Concat_98NumDims), this.NumDims.x_lstm_Constant_5_ou]);

            % Expand:
            [shape1001, x_lstm_Expand_1_outpNumDims] = soc_model_legacy.coder.ops.prepareExpandArgs(this.NumDims.x_lstm_Constant_1_ou, x_lstm_Concat_1_outp);
            x_lstm_Expand_1_outp = this.x_lstm_Constant_1_ou + zeros(shape1001);

            % Set graph output arguments
            x_lstm_Expand_1_outpNumDims1001 = coder.const(x_lstm_Expand_1_outpNumDims);

        end

    end

end