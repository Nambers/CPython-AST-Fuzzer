#include "helper.h"

void get_dummy_ast(ast_data_t **data_ptr)
{
	*data_ptr = (ast_data_t *)PyMem_Calloc(sizeof(ast_data_t), 1);
	(*data_ptr)->arena = _PyArena_New();
	(*data_ptr)->mod = init_dummy_ast((*data_ptr)->arena);
}

void get_UAF2_ast(ast_data_t **data_ptr)
{
	*data_ptr = (ast_data_t *)PyMem_Calloc(sizeof(ast_data_t), 1);
	(*data_ptr)->arena = _PyArena_New();
	(*data_ptr)->mod = init_UAF2((*data_ptr)->arena);
}

void free_ast(ast_data_t **data_ptr)
{
	_PyArena_Free((*data_ptr)->arena);
	PyMem_Free(*data_ptr);
	*data_ptr = NULL;
}

const char *data_backup;

size_t __attribute__((visibility("default"))) LLVMFuzzerCustomMutator(ast_data_t **data, size_t size, size_t max_size, unsigned int seed)
{
	if (data == NULL || *data == NULL || size != sizeof(ast_data_t *))
	{
		get_dummy_ast(data);
	}
	else
	{
		free_ast(data);
		get_UAF2_ast(data);
	}
	return sizeof(ast_data_t *);
}

int __attribute__((visibility("default"))) LLVMFuzzerInitialize(int *argc, char ***argv) {
	data_backup = (const char *)calloc(2048, 1);
    Py_Initialize();
    return 0;
}