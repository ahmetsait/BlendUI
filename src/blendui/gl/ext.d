module blendui.gl.ext;

import blendui.gl.types;
import blendui.gl.enums;
import blendui.gl.funcs;

bool GL_AMD_debug_output;
bool GL_ARB_debug_output;
bool GL_KHR_debug;

private nothrow @nogc extern(System)
{
	alias fp_glDebugMessageEnableAMD = void function(GLenum, GLenum, GLsizei, const(GLuint)*, GLboolean);
	alias fp_glDebugMessageInsertAMD = void function(GLenum, GLenum, GLuint, GLsizei, const(GLchar)*);
	alias fp_glDebugMessageCallbackAMD = void function(GLDEBUGPROCAMD, void*);
	alias fp_glGetDebugMessageLogAMD = GLuint function(GLuint, GLsizei, GLenum*, GLuint*, GLuint*, GLsizei*, GLchar*);
	alias fp_glDebugMessageControlARB = void function(GLenum, GLenum, GLenum, GLsizei, const(GLuint)*, GLboolean);
	alias fp_glDebugMessageInsertARB = void function(GLenum, GLenum, GLuint, GLenum, GLsizei, const(GLchar)*);
	alias fp_glDebugMessageCallbackARB = void function(GLDEBUGPROCARB, const(void)*);
	alias fp_glGetDebugMessageLogARB = GLuint function(GLuint, GLsizei, GLenum*, GLenum*, GLuint*, GLenum*, GLsizei*, GLchar*);
	alias fp_glDebugMessageControl = void function(GLenum, GLenum, GLenum, GLsizei, const(GLuint)*, GLboolean);
	alias fp_glDebugMessageInsert = void function(GLenum, GLenum, GLuint, GLenum, GLsizei, const(GLchar)*);
	alias fp_glDebugMessageCallback = void function(GLDEBUGPROC, const(void)*);
	alias fp_glGetDebugMessageLog = GLuint function(GLuint, GLsizei, GLenum*, GLenum*, GLuint*, GLenum*, GLsizei*, GLchar*);
	alias fp_glPushDebugGroup = void function(GLenum, GLuint, GLsizei, const(GLchar)*);
	alias fp_glPopDebugGroup = void function();
	alias fp_glObjectLabel = void function(GLenum, GLuint, GLsizei, const(GLchar)*);
	alias fp_glGetObjectLabel = void function(GLenum, GLuint, GLsizei, GLsizei*, GLchar*);
	alias fp_glObjectPtrLabel = void function(const(void)*, GLsizei, const(GLchar)*);
	alias fp_glGetObjectPtrLabel = void function(const(void)*, GLsizei, GLsizei*, GLchar*);
	alias fp_glGetPointerv = void function(GLenum, void**);
	alias fp_glDebugMessageControlKHR = void function(GLenum, GLenum, GLenum, GLsizei, const(GLuint)*, GLboolean);
	alias fp_glDebugMessageInsertKHR = void function(GLenum, GLenum, GLuint, GLenum, GLsizei, const(GLchar)*);
	alias fp_glDebugMessageCallbackKHR = void function(GLDEBUGPROCKHR, const(void)*);
	alias fp_glGetDebugMessageLogKHR = GLuint function(GLuint, GLsizei, GLenum*, GLenum*, GLuint*, GLenum*, GLsizei*, GLchar*);
	alias fp_glPushDebugGroupKHR = void function(GLenum, GLuint, GLsizei, const(GLchar)*);
	alias fp_glPopDebugGroupKHR = void function();
	alias fp_glObjectLabelKHR = void function(GLenum, GLuint, GLsizei, const(GLchar)*);
	alias fp_glGetObjectLabelKHR = void function(GLenum, GLuint, GLsizei, GLsizei*, GLchar*);
	alias fp_glObjectPtrLabelKHR = void function(const(void)*, GLsizei, const(GLchar)*);
	alias fp_glGetObjectPtrLabelKHR = void function(const(void)*, GLsizei, GLsizei*, GLchar*);
	alias fp_glGetPointervKHR = void function(GLenum, void**);
}

__gshared
{
	fp_glObjectPtrLabel glObjectPtrLabel;
	fp_glGetDebugMessageLog glGetDebugMessageLog;
	fp_glGetPointervKHR glGetPointervKHR;
	fp_glObjectLabelKHR glObjectLabelKHR;
	fp_glGetObjectPtrLabelKHR glGetObjectPtrLabelKHR;
	fp_glDebugMessageControlKHR glDebugMessageControlKHR;
	fp_glGetObjectPtrLabel glGetObjectPtrLabel;
	fp_glObjectLabel glObjectLabel;
	fp_glGetObjectLabel glGetObjectLabel;
	fp_glDebugMessageCallbackARB glDebugMessageCallbackARB;
	fp_glDebugMessageControl glDebugMessageControl;
	fp_glDebugMessageInsertAMD glDebugMessageInsertAMD;
	fp_glDebugMessageInsert glDebugMessageInsert;
	fp_glDebugMessageControlARB glDebugMessageControlARB;
	fp_glGetDebugMessageLogKHR glGetDebugMessageLogKHR;
	fp_glGetObjectLabelKHR glGetObjectLabelKHR;
	fp_glDebugMessageEnableAMD glDebugMessageEnableAMD;
	fp_glDebugMessageCallbackKHR glDebugMessageCallbackKHR;
	fp_glPushDebugGroup glPushDebugGroup;
	fp_glGetPointerv glGetPointerv;
	fp_glPushDebugGroupKHR glPushDebugGroupKHR;
	fp_glDebugMessageCallback glDebugMessageCallback;
	fp_glDebugMessageInsertKHR glDebugMessageInsertKHR;
	fp_glPopDebugGroupKHR glPopDebugGroupKHR;
	fp_glObjectPtrLabelKHR glObjectPtrLabelKHR;
	fp_glGetDebugMessageLogARB glGetDebugMessageLogARB;
	fp_glPopDebugGroup glPopDebugGroup;
	fp_glDebugMessageInsertARB glDebugMessageInsertARB;
	fp_glGetDebugMessageLogAMD glGetDebugMessageLogAMD;
	fp_glDebugMessageCallbackAMD glDebugMessageCallbackAMD;
}
