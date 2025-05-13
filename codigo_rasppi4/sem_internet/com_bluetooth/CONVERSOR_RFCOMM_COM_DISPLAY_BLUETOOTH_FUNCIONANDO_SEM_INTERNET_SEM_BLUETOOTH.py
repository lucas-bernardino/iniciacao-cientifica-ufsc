#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*
Você deve implementar uma rede Perceptron, de uma única camada, para problemas de classificação binária
(isto é, duas classes).
*/

#define ARR_SIZE(x)  ((int) sizeof(x) / sizeof((x)[0]))

// total number of rows of the input csv file used to train the nn


// // if this is defined than the weights will be printed afther all the epochs
#define VERBOSE


float current_output(float* input, float* weights, int len_weights) {
    /* ex:
    input = {0, 1}
    weights = {0, 0, 0}
    len_weights = 3
    */
    float sum = weights[0];
    for (int i = 0; i < (len_weights - 1); i++) {
        sum += input[i] * weights[i+1];
    }
    return sum;
}

float activate_function(float output) {
    if (output > 0) {
        return 1.0;
    }
    return -1.0;
}

void update_weight(float* input, float* weight, float learning_rate, float desired_output, int len_weights, int iteration) {
    
    /*
    we need to do this:
    w(n+1) = w(n) + η(n) (d(n) – y(n)) x(n)

    this function is basically doing that.
    it calls current_output, that will get the sum of input x weights.
    then activate_function is called on this sum, to get 1 or -1.
    the factor is a variable that basically holds this expression η(n) * (d(n) – y(n)),
    where n(n) is the learning_rate, d(n) is the desired_output passed by the caller and y(n) is the y.

    to update the weights, we basically just update the weights (need to do it separetly since 
    it doesn't involve input multiplication) and then we loop over each element in the weights array to update it.
    */
    
    float output = current_output(input, weight, len_weights);
    float y = activate_function(output);
    float factor = learning_rate * (desired_output - y);

    // update bias
    weight[0] = weight[0] + factor;

    // update rest of the weights
    for (int i = 0; i < (len_weights - 1); i++) {
        weight[i+1] = weight[i+1] + (factor * input[i]);
    }
}


// helper function to get the value of a given column in the csv.
char* get_csv_column(char* line, int num)
{
    char* tok;
    for (tok = strtok(line, ",");
            tok && *tok;
            tok = strtok(NULL, ",\n"))
    {
        if (!--num)
            return tok;
    }
    return NULL;
}

// this function will read the input csv, parse it, and save the input values in the input matrix and the output values in the output array
// the col_inputs param are the columns of interest in the csv and the col_output is the output column in the csv
void load_csv(char* filename, int* col_inputs, int len_col_inputs, int num_csv_rows, float input[num_csv_rows - 1][len_col_inputs], float* output, int col_output) {

    FILE* fp = fopen(filename, "r");

    if (!fp) {
        printf("[ERROR] File does not exist. Aborting...\n");
        exit(1);
    }

    // this will skip the first line (we need to ignore the column names) of the csv
    fscanf(fp, "%*[^\n]\n");

    char* line = NULL;
    size_t len = 0;
    size_t read;
    int row = 0;

    // for every line in the csv, handle input and output columns
    while ((read = getline(&line, &len, fp)) != -1) {

        // handle input columns
        for (int i = 0; i < len_col_inputs; i++) {
            char* tmp = strdup(line);
            const char* col = get_csv_column(tmp, col_inputs[i]);
            if (col) {
                input[row][i] = atof(col);
            }
            free(tmp);
        }

        // handle output columns
        char* tmp = strdup(line);
        const char* col = get_csv_column(tmp, col_output);
        if (col) {
            output[row] = atof(col);
        }

        
        free(tmp);
        row++;
    }

    free(line);
    fclose(fp);
}

/*
w0, w1, w2
3, 4, 5
*/
void save_csv(FILE* fp, float* weights, int len_weights) {
    for (int i = 0; i < len_weights; i++) {
        if (i == (len_weights - 1)) { // last iteration of the loop
            fprintf(fp,"%f\n", weights[i]);
            break;
        }
        fprintf(fp,"%f, ", weights[i]);
    }
} 

float* nn_train(int len_rows, int len_columns, float input[len_rows][len_columns], float* output, float learning_rate, int epochs, char* output_file) {
    
    /*
    the weights will always have the size of the input + 1. Like
    input: {0, 1}
    weights: {0, 0, 0}
    since weights[0] is the bias
    */
    
    // this is like using malloc and then memset 
    int len_weights = len_columns + 1;

    float* weight = calloc(sizeof(float), len_weights);

    FILE* fp = fopen(output_file, "w+");

    // this is just writing the column names in the output file, like 'w0, w1, w2, ..., wn'
    for (int i = 0; i < len_weights; i++) {
        if (i == (len_weights - 1)) { // last iteration of the loop
            fprintf(fp,"w%d\n", i);
            break;
        }
        fprintf(fp,"w%d, ", i);
    }

    for (int ep = 0; ep < epochs; ep++) {
        for (int i = 0; i < len_rows; i++) {
                update_weight(input[i], weight, learning_rate, output[i], len_weights, i);
                save_csv(fp, weight, len_weights);
        }
    }

    #ifdef VERBOSE
        printf("[PERCEPTRON - INFO] Results for %s\n", output_file);
        for (int i = 0; i < len_weights; i++) {
            printf("weight[%d]: %f\n", i, weight[i]);
        }
        printf("\n");
    #endif

    fclose(fp);

    return weight;
}

int main (int argc, char** argv) {
    // float input[4][2] = {
    //     {0.0, 0.0},
    //     {0.0, 1.0},
    //     {1.0, 0.0},
    //     {1.0, 1.0}
    // };
    
    // float output[4] = {-1.0, -1.0, -1.0, 1.0};
    // float learning_rate = 1.0;
    // int epochs = 15;
    
    // float* weights = nn_train(ARR_SIZE(input), ARR_SIZE(input[0]), input, output, learning_rate, 6, "weights.csv");
    // int len_weights = ARR_SIZE(input[0]) + 1;
    // for (int i = 0; i < len_weights; i++) {
    //     printf("weight[%d]: %f\n", i, weights[i]);
    // }


    if (argc != 4) {
        printf("[ERROR] Invalid input. Should be: './perceptron <input_file> <output_file> <num_rows>. Aborting...\n");
        exit(1);
    }


    int fields[] = {4, 5};

    // The fields will be appended in the 'fields.txt' file so that pos_processor.py can use it later
    FILE* save_fp = fopen("fields.txt", "w+");

    for (int i = 0; i < ARR_SIZE(fields); ++i) {
        if (i == (ARR_SIZE(fields) - 1)) { // last iteration of the loop
            fprintf(save_fp,"%d\n", fields[i]);
            break;
        }
        fprintf(save_fp,"%d, ", fields[i]);
    } 

    fclose(save_fp);

    // this is the input matrix. The number of rows is minus 1 since there's the column names, so we need 
    // to get rid of that. The columns will be the size of the fields of interest.

    // argv[3] is the total number of csv_rows passed as argument
    const int CSV_ROWS = atoi(argv[3]);

    float input[CSV_ROWS - 1][ARR_SIZE(fields)];

    float output[CSV_ROWS - 1];

    load_csv(argv[1], fields, ARR_SIZE(fields), CSV_ROWS, input, output, 6);
    float* weights = nn_train(ARR_SIZE(input), ARR_SIZE(input[0]), input, output, 1, 100, argv[2]);

    return 0;
}
