#include "ruby.h"

VALUE bitwise_ops_info = Qnil;

void Init_BitwiseOperations();

VALUE method_bitcount_64(VALUE self, VALUE number);
VALUE method_hamming_distance_64(VALUE self, VALUE a, VALUE b);
VALUE method_hamming_step(VALUE self, VALUE hamming_distance);
VALUE method_hamming_path(VALUE self, VALUE hamming_distance);
int bitcount (unsigned long n);

void Init_BitwiseOperations() {
	bitwise_ops_info = rb_define_module("BitwiseOperations");
	rb_define_method(bitwise_ops_info, "bitcount_64", method_bitcount_64, 1);
	rb_define_method(bitwise_ops_info, "hamming_distance_64", method_hamming_distance_64, 2);
	rb_define_method(bitwise_ops_info, "hamming_step", method_hamming_step, 1);
	rb_define_method(bitwise_ops_info, "hamming_path", method_hamming_path, 1);
}

#define TWO(c)     (0x1ul << (c))
#define MASK(c) (((unsigned long)(-1)) / (TWO(TWO(c)) + 1ul))
#define COUNT(x,c) ((x) & MASK(c)) + (((x) >> (TWO(c))) & MASK(c))

VALUE method_hamming_path(VALUE self, VALUE hamming_distance) {
	int i = 0;
	int steps = bitcount(NUM2ULONG(hamming_distance));
	long signed_distance = NUM2LONG(hamming_distance);
	VALUE hamming_path = rb_ary_new2(steps);
	for (i = 0; i < steps; i += 1)
	{
		long step = signed_distance & (- signed_distance);
		signed_distance -= step;
		rb_ary_push(hamming_path, LONG2NUM(step));
	}
	return hamming_path;
}

VALUE method_hamming_step(VALUE self, VALUE hamming_distance) {
   return LONG2NUM(NUM2LONG(hamming_distance) & (-NUM2LONG(hamming_distance)));
}

VALUE method_hamming_distance_64(VALUE self, VALUE a, VALUE b) {
	return INT2NUM(bitcount(NUM2ULONG(a)^NUM2ULONG(b)));
}

VALUE method_bitcount_64(VALUE self, VALUE number) {
   return INT2NUM(bitcount(NUM2ULONG(number)));
}

int bitcount(unsigned long n)  {
   n = COUNT(n, 0) ;
   n = COUNT(n, 1) ;
   n = COUNT(n, 2) ;
   n = COUNT(n, 3) ;
   n = COUNT(n, 4) ;
   n = COUNT(n, 5) ;
   return n ;
}


