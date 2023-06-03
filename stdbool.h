#ifndef __MY_STDBOOL_H_
#define __MY_STDBOOL_H_


#undef bool
#undef true
#undef false
#undef __bool_true_false_are_defined
#ifndef __cplusplus
#define bool _Bool
#endif /* not __cplusplus */
#define true 1
#define false 0
#define __bool_true_false_are_defined 1


#endif /* __MY_STDBOOL_H_ */
