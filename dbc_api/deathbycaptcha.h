/**
 * Death By Captcha socket API client.
 * Feel free to use however you see fit.
 * Written by Sergey Kolchin <ksa242@gmail.com>
 */

#ifndef _C_DEATHBYCAPTCHA_H_
#define _C_DEATHBYCAPTCHA_H_

#include <sys/types.h>
#ifdef _WIN32
    #include <winsock2.h>
    #include <ws2tcpip.h>
#else
    #include <semaphore.h>
    #include <sys/socket.h>
    #include <netdb.h>
#endif  /* _WIN32 */

#ifdef _WIN32
    #define DBC_DLL_PUBLIC __declspec(dllexport)
#else
    #define DBC_DLL_PUBLIC __attribute__ ((visibility ("default")))
#endif  /* _WIN32 */

#ifdef __cplusplus
extern "C"
{
#endif  /* __cplusplus */


#define DBC_API_VERSION "DBC/C v4.1.1"
#define DBC_SOFTWARE_VENDOR 0

#define DBC_HOST "api.deathbycaptcha.com"
#define DBC_FIRST_PORT 8123
#define DBC_LAST_PORT 8130

#define DBC_TIMEOUT 60
#define DBC_INTERVAL 5

#define DBC_TERMINATOR "\r\n"


typedef struct {
    char *username, *password;
    unsigned int user_id;
    unsigned int is_banned;
    unsigned int is_verbose;
    double balance;
    int socket;
#ifdef _WIN32
    HANDLE socket_lock;
#endif  /* _WIN32 */
    struct addrinfo *server_addr;
} dbc_client;

typedef struct {
    unsigned int id;
    unsigned int is_correct;
    char *text;
} dbc_captcha;


/**
 * Clean/free the API client up.
 */
extern DBC_DLL_PUBLIC void dbc_close(dbc_client *client);

/**
 * Initialize a new Death by Captcha socket API client using supplied
 * credentials.  Returns 0 on success, -1 of failures.
 */
extern DBC_DLL_PUBLIC int dbc_init(dbc_client *client,
                                   const char *username,
                                   const char *password);

/**
 * Fetch user's balance (in US cents).
 */
extern DBC_DLL_PUBLIC double dbc_get_balance(dbc_client *client);


/**
 * Clean/free the CAPTCHA instance up.
 */
extern DBC_DLL_PUBLIC void dbc_close_captcha(dbc_captcha *captcha);

/**
 * Initialize a new CAPTCHA instance.  Returns 0 on success, -1 on failures.
 */
extern DBC_DLL_PUBLIC int dbc_init_captcha(dbc_captcha *captcha);

/**
 * Fetch an uploaded CAPTCHA details.  Returns 0 on success, -1 otherwise.
 */
int DBC_DLL_PUBLIC dbc_get_captcha(dbc_client *client,
                                   dbc_captcha *captcha,
                                   unsigned int id);

/**
 * Report an incorrectly solved CAPTCHA.
 * Returns 0 on success, -1 on failures.
 */
extern DBC_DLL_PUBLIC int dbc_report(dbc_client *client, dbc_captcha *captcha);

/**
 * Upload a CAPTCHA from buffer and poll for its status with desired timeout
 * (in seconds).  Returns 0 if solved; cleans the supplied CAPTCHA instance
 * up, and returns -1 on failures.
 */
extern DBC_DLL_PUBLIC int dbc_decode(dbc_client *client,
                                     dbc_captcha *captcha,
                                     const char *buf,
                                     size_t buflen,
                                     unsigned int timeout);

/**
 * Upload a CAPTCHA from a stream and poll for its status with desired timeout
 * (in seconds).  See dbc_decode() for details.
 */
extern DBC_DLL_PUBLIC int dbc_decode_file(dbc_client *client,
                                          dbc_captcha *captcha,
                                          FILE *f,
                                          unsigned int timeout);

#ifdef __cplusplus
}
#endif  /* __cplusplus */

#endif  /* !_C_DEATHBYCAPTCHA_H_ */
