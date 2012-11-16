
#ifndef STRING_UTILS_H_INCLUDED
#define STRING_UTILS_H_INCLUDED

#include <string>
#include <algorithm>

std::string format_msg ( const char * format_str, ... );
void format_buffer ( std::string * result, const char * format_str, ... );
std::string format_errno_msg ( int errno_val,
                               const char * prefix_msg_fmt,
                               ... );

std::string ip_address_to_text ( const struct in_addr * addr );

bool str_starts_with ( const std::string * str, const std::string * prefix );
bool str_remove_prefix ( std::string * str, const std::string *  prefix );

inline void rtrim ( std::string * const s )
{
  s->erase( std::find_if( s->rbegin(),
                          s->rend(),
                          std::not1(std::ptr_fun<int, int>(std::isspace))).base(),
            s->end() );
}

inline void ltrim ( std::string * const s )
{
  s->erase( s->begin(),
            std::find_if( s->begin(), s->end(),
                          std::not1( std::ptr_fun<int, int>(std::isspace) ) ) );
}

#endif  // Include this header only once.
