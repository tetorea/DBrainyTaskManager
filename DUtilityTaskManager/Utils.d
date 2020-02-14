module Utils;

import std.variant;

ulong dimensions( Variant v ){
	if( !v.hasValue ) return 0;

	ulong dimensions = 0;
	try{
		dimensions = v.length;
	}catch( Exception e ) return 1;

	return dimensions;
}

auto typeBase( Variant v ){
	switch( v.dimensions ){
		case 0 :
		case 1 : return v.type;
		default : return v[0].type;
	}
}

//////////////////////////////////////////////////////////////////////
//          Copyright Mario Kröplin 2019.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

// downloaded from https://github.com/linkrope/log on 2020/02/13

import std.algorithm;
import std.array;
import std.conv;
import std.datetime;
import std.format;
import std.range;
import std.stdio;
import std.string;
import std.traits;
import std.typecons;

/// Defines the importance of a log message.
enum LogLevel
{
    /// detailed tracing
    trace = 1,
    /// useful information
    info = 2,
    /// potential problem
    warn = 4,
    /// recoverable _error
    error = 8,
    /// _fatal failure
    fatal = 16,
}

/// Returns a bit set containing the level and all levels above.
@safe
uint orAbove(LogLevel level) pure
{
    return [EnumMembers!LogLevel].find(level).reduce!"a | b";
}

///
unittest
{
    with (LogLevel)
    {
        assert(trace.orAbove == (trace | info | warn | error | fatal));
        assert(fatal.orAbove == fatal);
    }
}

/// Returns a bit set containing the level and all levels below.
@safe
uint orBelow(LogLevel level) pure
{
    return [EnumMembers!LogLevel].retro.find(level).reduce!"a | b";
}

///
unittest
{
    with (LogLevel)
    {
        assert(trace.orBelow == trace);
        assert(fatal.orBelow == (trace | info | warn | error | fatal));
    }
}

@safe
bool disabled(LogLevel level) pure
{
    uint levels = 0;

    with (LogLevel)
    {
        version (DisableTrace)
            levels |= trace;
        version (DisableInfo)
            levels |= info;
        version (DisableWarn)
            levels |= warn;
        version (DisableError)
            levels |= error;
        version (DisableFatal)
            levels |= fatal;
    }
    return (level & levels) != 0;
}

private alias Sink = OutputRange!(const(char)[]);

struct Log
{
    private Logger[] loggers;

    // preallocate so we can fill it in @nogc fileDescriptors()
    private int[] buffer;

    private uint levels;

    this(Logger[] loggers ...)
    in
    {
        assert(loggers.all!"a !is null");
    }
    body
    {
        this.loggers = loggers.dup;
        buffer = new int[this.loggers.length];
        levels = reduce!((a, b) => a | b.levels)(0, this.loggers);
    }

    public int[] fileDescriptors() @nogc nothrow @safe
		in (buffer.length >= loggers.length)
		{
			size_t length = 0;

			foreach (logger; loggers)
			{
				const fileDescriptor = logger.fileDescriptor;

				if (!fileDescriptor.isNull)
					buffer[length++] = fileDescriptor.get;
			}
			return buffer[0 .. length];
		}

    alias trace = append!(LogLevel.trace);
    alias info = append!(LogLevel.info);
    alias warn = append!(LogLevel.warn);
    alias error = append!(LogLevel.error);
    alias fatal = append!(LogLevel.fatal);

    private struct Fence {}  // argument cannot be provided explicitly

    template append(LogLevel level)
    {
        void append(alias fmt, Fence _ = Fence(), string file = __FILE__, size_t line = __LINE__, A...)
            (lazy A args)
			if (isSomeString!(typeof(fmt)))
			{
				static if (!level.disabled)
					if (level & levels)
						_append(level, file, line,
								(scope Sink sink) { sink.formattedWrite!fmt(args); });
			}

        void append(Fence _ = Fence(), string file = __FILE__, size_t line = __LINE__, Char, A...)
            (const Char[] fmt, lazy A args)
        {
            static if (!level.disabled)
                if (level & levels)
                    _append(level, file, line,
							(scope Sink sink) { sink.formattedWrite(fmt, args); });
        }

        void append(Fence _ = Fence(), string file = __FILE__, size_t line = __LINE__, A)
            (lazy A arg)
        {
            static if (!level.disabled)
                if (level & levels)
                    _append(level, file, line,
							(scope Sink sink) { sink.put(arg.to!string); });
        }
    }

    private void _append(LogLevel level, string file, size_t line,
						 scope void delegate(scope Sink sink) putMessage)
    {
        EventInfo eventInfo;

        eventInfo.time = Clock.currTime;
        eventInfo.level = level;
        eventInfo.file = file;
        eventInfo.line = line;

        foreach (logger; loggers)
            if (level & logger.levels)
                logger.append(eventInfo, putMessage);
    }
}

__gshared Log log;

shared static this()
{
    log = Log(stderrLogger);
}

/// Represents information about a logging event.
struct EventInfo
{
    /// local _time of the event
    SysTime time;
    /// importance of the event
    LogLevel level;
    /// _file name of the event source
    string file;
    /// _line number of the event source
    size_t line;
}

auto fileLogger(alias Layout = layout)
(string name, uint levels = LogLevel.info.orAbove)
{
    return new FileLogger!Layout(name, levels);
}

auto stderrLogger(alias Layout = layout)
(uint levels = LogLevel.warn.orAbove)
{
    return new FileLogger!Layout(stderr, levels);
}

auto stdoutLogger(alias Layout = layout)
(uint levels = LogLevel.info.orAbove)
{
    return new FileLogger!Layout(stdout, levels);
}

auto rollingFileLogger(alias Layout = layout)
(string name, size_t count, size_t size, uint levels = LogLevel.info.orAbove)
{
    return new RollingFileLogger!Layout(name ~ count.archiveFiles(name), size, levels);
}


/// Returns n file names based on path for archived files.
@safe
string[] archiveFiles(size_t n, string path)
{
    import std.path : extension, stripExtension;
    import std.range : iota;

    auto length = n.to!string.length;

    return n.iota
        .map!(i => format!"%s-%0*s%s"(path.stripExtension, length, i + 1, path.extension))
        .array;
}

///
unittest
{
    assert(1.archiveFiles("dir/log.ext") == ["dir/log-1.ext"]);
    assert(10.archiveFiles("log").startsWith("log-01"));
    assert(10.archiveFiles("log").endsWith("log-10"));
}

abstract class Logger
{
    private uint levels;

    this(uint levels)
    {
        this.levels = levels;
    }

    abstract void append(const ref EventInfo eventInfo,
						 scope void delegate(scope Sink sink) putMessage);

    // Exposed so that client code can write data to the log file directly in
    // emergency situations, such as a crash.
    // Returns null if the logger does not use a straightforward file descriptor.
    // The effect of writing to the returned handle should be some form of
    // readable logging.
    Nullable!int fileDescriptor() const @nogc nothrow @safe
    {
        return Nullable!int();
    }
}

class FileLogger(alias Layout) : Logger
{
    // must be static to be thread-local
    private static Appender!(char[]) buffer;

    private File file;

    // store cause it's awkward to derive in fileDescriptor, which must be signal-safe
    private int fileno;

    this(string name, uint levels = LogLevel.info.orAbove)
    {
        super(levels);
        file = File(name, "ab");
        fileno = file.fileno;
    }

    this(File file, uint levels = LogLevel.info.orAbove)
    {
        super(levels);
        this.file = file;
        fileno = this.file.fileno;
    }

    override void append(const ref EventInfo eventInfo,
						 scope void delegate(scope Sink sink) putMessage)
    {
        import std.algorithm.mutation : swap;

        // avoid problems if toString functions call log - "borrow" static buffer
        Appender!(char[]) buffer;

        buffer.swap(this.buffer);

        // put it back on exit, so the next call can use it
        scope(exit)
        {
            buffer.clear;
            buffer.swap(this.buffer);
        }

        Layout(buffer, eventInfo, putMessage);
        file.lockingTextWriter.put(buffer.data);
        file.flush;
    }

    override Nullable!int fileDescriptor() const @nogc nothrow @safe
    {
        return Nullable!int(fileno);
    }
}

class RollingFileLogger(alias Layout) : FileLogger!Layout
{
    private string[] names;

    private size_t size;

    this(const string[] names, size_t size, uint levels = LogLevel.info.orAbove)
    in
    {
        assert(!names.empty);
    }
    body
    {
        this.names = names.dup;
        this.size = size;
        super(this.names.front, levels);
    }

    override void append(const ref EventInfo eventInfo,
						 scope void delegate(scope Sink sink) putMessage)
    {
        synchronized (this)
        {
            if (file.size >= size)
                roll;
            super.append(eventInfo, putMessage);
        }
    }

    private void roll()
    {
        import std.file : exists, rename;

        foreach_reverse (i, destination; names[1 .. $])
        {
            const source = names[i];

            if (source.exists)
                rename(source, destination);
        }
        file.open(names.front, "wb");
        fileno = file.fileno;
    }
}


// Time Thread Category Context layout
void layout(Writer)(ref Writer writer, const ref EventInfo eventInfo,
					scope void delegate(scope Sink sink) putMessage)
{
    import core.thread : Thread;

    with (eventInfo)
    {
        time._toISOExtString(writer);
        writer.formattedWrite!" %-5s %s:%s"(level, file, line);

        if (Thread thread = Thread.getThis)
        {
            string name = thread.name;

            if (!name.empty)
                writer.formattedWrite!" [%s]"(name);
        }

        writer.put(' ');
        putMessage(outputRangeObject!(const(char)[])(writer));
        writer.put('\n');
    }
}

unittest
{
    EventInfo eventInfo;

    eventInfo.time = SysTime.fromISOExtString("2003-02-01T11:55:00.123456Z");
    eventInfo.level = LogLevel.error;
    eventInfo.file = "log.d";
    eventInfo.line = 42;

    auto writer = appender!string;

    layout(writer, eventInfo, (scope Sink sink) { sink.put("don't panic"); });
    assert(writer.data == "2003-02-01T11:55:00.123+00:00 error log.d:42 don't panic\n");
}

// SysTime.toISOExtString has no fixed length and no time-zone offset for local time
private void _toISOExtString(W)(SysTime time, ref W writer)
if (isOutputRange!(W, char))
{
    (cast (DateTime) time).toISOExtString(writer);
    writer.formattedWrite!".%03d"(time.fracSecs.total!"msecs");
    time.utcOffset._toISOString(writer);
}

unittest
{
    auto dateTime = DateTime(2003, 2, 1, 12);
    auto fracSecs = 123_456.usecs;
    auto timeZone =  new immutable SimpleTimeZone(1.hours);
    auto time = SysTime(dateTime, fracSecs, timeZone);
    auto writer = appender!string;

    time._toISOExtString(writer);
    assert(writer.data == "2003-02-01T12:00:00.123+01:00");
}

// SimpleTimeZone.toISOString is private
@safe
private void _toISOString(W)(Duration offset, ref W writer)
if (isOutputRange!(W, char))
{
    uint hours;
    uint minutes;

    abs(offset).split!("hours", "minutes")(hours, minutes);
    writer.formattedWrite!"%s%02d:%02d"(offset.isNegative ? '-' : '+', hours, minutes);
}

unittest
{
    auto writer = appender!string;

    90.minutes._toISOString(writer);
    assert(writer.data == "+01:30");
}

unittest
{
    auto writer = appender!string;

    (-90).minutes._toISOString(writer);
    assert(writer.data == "-01:30");
}