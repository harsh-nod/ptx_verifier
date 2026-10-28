dim N; array gate[N]; array value[N]; array out[N]; out[i]=gate[i]*value[i]/(1+exp(-gate[i]));
