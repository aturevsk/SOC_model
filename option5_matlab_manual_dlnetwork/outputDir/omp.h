#ifndef OMP_H
#define OMP_H
typedef int omp_lock_t;
typedef int omp_nest_lock_t;
static inline int omp_get_max_threads(void) { return 1; }
static inline int omp_get_num_threads(void) { return 1; }
static inline int omp_get_thread_num(void) { return 0; }
static inline void omp_init_nest_lock(omp_nest_lock_t *l) { (void)l; }
static inline void omp_destroy_nest_lock(omp_nest_lock_t *l) { (void)l; }
static inline void omp_set_nest_lock(omp_nest_lock_t *l) { (void)l; }
static inline void omp_unset_nest_lock(omp_nest_lock_t *l) { (void)l; }
#endif
