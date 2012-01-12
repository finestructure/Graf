/**
 * Death By Captcha socket API client.
 * Feel free to use however you see fit.
 * Written by Sergey Kolchin <ksa242@gmail.com>
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>
#include <sys/types.h>
#include <errno.h>
#include <fcntl.h>
#ifdef _WIN32
    #define WINVER 0x0502
    #ifndef WIN32_LEAN_AND_MEAN
        #define WIN32_LEAN_AND_MEAN
    #endif  /* !WIN32_LEAN_AND_MEAN */
    #include <windows.h>
    #include <windef.h>
    #include <winsock2.h>
    #include <ws2tcpip.h>
#else
    #include <semaphore.h>
    #include <sys/socket.h>
    #include <sys/select.h>
    #include <netdb.h>
    #include <unistd.h>
#endif  /* _WIN32 */

#include "base64.h"
#include "cJSON.h"

#include "deathbycaptcha.h"


// prototypes
size_t dbc_load_file(FILE *f, char **buf);
unsigned short dbc_get_random_port();
unsigned short dbc_get_random_port();
int dbc_disconnect(dbc_client *client);
int dbc_connect(dbc_client *client);
int dbc_connected(dbc_client *client);
void dbc_update_client(dbc_client *client, cJSON *response);
void dbc_update_captcha(dbc_captcha *captcha, cJSON *response);
cJSON *dbc_send_and_recv(dbc_client *client, const char *sbuf);
cJSON *dbc_call(dbc_client *client, const char *cmd, cJSON *args);
int dbc_upload(dbc_client *client,
               dbc_captcha *captcha,
               const char *buf,
               size_t buflen);
int dbc_upload_file(dbc_client *client,
                    dbc_captcha *captcha,
                    FILE *f);
unsigned short dbc_get_random_port();


/**
 * Load a file into a buffer.  Returns the number of characters loaded.
 */
size_t dbc_load_file(FILE *f, char **buf)
{
    size_t buflen = 0;
    if (NULL == f) {
        fprintf(stderr, "Invalid CAPTCHA image file stream\n");
    } else {
        char *pbuf = NULL;
        int r = 0, chunk_size = 2048;
        *buf = (char *)calloc(chunk_size, sizeof(char));
        while (0 < (r = fread(*buf + buflen, sizeof(char), chunk_size, f))) {
            buflen += r;
            if (NULL == (pbuf = (char *)realloc(*buf, (buflen + chunk_size) * sizeof(char)))) {
                fprintf(stderr, "realloc(): %d\n", errno);
                buflen = 0;
                break;
            } else {
                *buf = pbuf;
            }
        }
        if (0 < buflen) {
            if (NULL == (pbuf = (char *)realloc(*buf, buflen))) {
                fprintf(stderr, "realloc(): %d\n", errno);
                buflen = 0;
            } else {
                *buf = pbuf;
            }
        }
        if (0 == buflen && NULL != *buf) {
            free(*buf);
        }
    }
    return buflen;
}

/**
 * Choose a random socket API port.
 */
unsigned short dbc_get_random_port()
{
    srand(time(NULL));
    return DBC_FIRST_PORT + (int)(((float)rand() / RAND_MAX) * (DBC_LAST_PORT - DBC_FIRST_PORT + 1));
}


/**
 * Close opened socket API connection.
 */
int dbc_disconnect(dbc_client *client)
{
    if (client->is_verbose) {
        fprintf(stderr, "%d CLOSE\n", (int)time(NULL));
    }
#ifdef _WIN32
    if (INVALID_SOCKET != client->socket) {
        shutdown(client->socket, SD_BOTH);
        closesocket(client->socket);
        client->socket = INVALID_SOCKET;
    }
#else
    if (-1 != client->socket) {
        shutdown(client->socket, SHUT_RDWR);
        close(client->socket);
        client->socket = -1;
    }
#endif  /* _WIN32 */
    return client->socket;
}

/**
 * Open a socket connection to the API server.
 * Returns 0 on success, -1 otherwise.
 */
int dbc_connect(dbc_client *client)
{
    struct addrinfo *sa = client->server_addr;
#ifdef _WIN32
    for (; INVALID_SOCKET == client->socket && NULL != sa; sa = sa->ai_next) {
        if (client->is_verbose) {
            fprintf(stderr, "%d CONN\n", (int)time(NULL));
        }
        client->socket = socket(sa->ai_family, sa->ai_socktype, sa->ai_protocol);
        if (INVALID_SOCKET == client->socket) {
            fprintf(stderr, "socket(): %d\n", WSAGetLastError());
        } else {
            unsigned long nbio = 1;
            ioctlsocket(client->socket, FIONBIO, &nbio);
            ((struct sockaddr_in *)(sa->ai_addr))->sin_port = htons(dbc_get_random_port());
            if (SOCKET_ERROR == connect(client->socket, sa->ai_addr, sa->ai_addrlen)) {
                int wsaerr = WSAGetLastError();
                if (WSAEWOULDBLOCK != wsaerr && WSAEINPROGRESS != wsaerr) {
                    fprintf(stderr, "connect(): %d\n", wsaerr);
                    dbc_disconnect(client);
                }
            }
        }
    }
    return (INVALID_SOCKET == client->socket) ? -1 : 0;
#else
    for (; -1 == client->socket && NULL != sa; sa = sa->ai_next) {
        if (client->is_verbose) {
            fprintf(stderr, "%d CONN\n", (int)time(NULL));
        }
        client->socket = socket(sa->ai_family, sa->ai_socktype, sa->ai_protocol);
        if (-1 == client->socket) {
            fprintf(stderr, "socket(): %d\n", errno);
        } else {
            fcntl(client->socket, F_SETFL, fcntl(client->socket, F_GETFL) | O_NONBLOCK);
            ((struct sockaddr_in *)(sa->ai_addr))->sin_port = htons(dbc_get_random_port());
            if (connect(client->socket, sa->ai_addr, sa->ai_addrlen)) {
                if (EINPROGRESS != errno) {
                    fprintf(stderr, "connect(): %d\n", errno);
                    dbc_disconnect(client);
                }
            }
        }
    }
    return (-1 == client->socket) ? -1 : 0;
#endif  /* _WIN32 */
}

int dbc_connected(dbc_client *client)
{
#ifdef _WIN32
    return INVALID_SOCKET != client->socket ? 1 : 0;
#else
    return -1 != client->socket ? 1 : 0;
#endif  /* _WIN32 */
}

/**
 * Update client structure from API response.
 */
void dbc_update_client(dbc_client *client, cJSON *response)
{
    if (NULL != response && NULL != client) {
        cJSON *tmp = NULL;
        client->user_id = (NULL != (tmp = cJSON_GetObjectItem(response, "user")))
            ? tmp->valueint
            : 0;
        client->balance = 0.0;
        client->is_banned = 0;
        if (0 < client->user_id) {
            if (NULL != (tmp = cJSON_GetObjectItem(response, "balance"))) {
                client->balance = tmp->valuedouble;
            }
            if (NULL != (tmp = cJSON_GetObjectItem(response, "is_banned"))) {
                client->is_banned = tmp->valueint;
            }
        }
    }
}

/**
 * Update CAPTCHA structure from API response.
 */
void dbc_update_captcha(dbc_captcha *captcha, cJSON *response)
{
    dbc_close_captcha(captcha);
    if (NULL != response && NULL != captcha) {
        cJSON *tmp = NULL;
        if (NULL != (tmp = cJSON_GetObjectItem(response, "captcha"))) {
            captcha->id = tmp->valueint;
            if (0 < captcha->id) {
                if (NULL != (tmp = cJSON_GetObjectItem(response, "text"))) {
                    if (cJSON_NULL != tmp->type && 0 < strlen(tmp->valuestring)) {
                        captcha->text = (char *)calloc(strlen(tmp->valuestring) + 1, sizeof(char));
                        strcpy(captcha->text, tmp->valuestring);
                    }
                }
                if (NULL != (tmp = cJSON_GetObjectItem(response, "is_correct"))) {
                    captcha->is_correct = tmp->valueint;
                }
            }
        }
    }
}

cJSON *dbc_send_and_recv(dbc_client *client, const char *sbuf)
{
    cJSON *response = NULL;

    struct timeval tv;
    int r = 0;
    size_t sent = 0, sbuflen = strlen(sbuf),
           received = 0, rchunk = 256;
    char *rbuf = NULL;

    if (client->is_verbose) {
        fprintf(stderr, "%d SEND: %d %s\n", (int)time(NULL), (int)sbuflen, sbuf);
    }

    if (dbc_connect(client)) {
        return NULL;
    } else {
        rbuf = (char *)calloc(rchunk, sizeof(char));
    }

    while (1) {
        fd_set rd, wr, ex;
        FD_ZERO(&rd);
        FD_ZERO(&wr);
        if (sbuflen > sent) {
            FD_SET(client->socket, &wr);
        } else {
            FD_SET(client->socket, &rd);
        }
        FD_ZERO(&ex);
        FD_SET(client->socket, &ex);

        tv.tv_sec = 4 * DBC_INTERVAL;
        tv.tv_usec = 0;

        if (-1 == (r = select(client->socket + 1, &rd, &wr, &ex, &tv))) {
            fprintf(stderr, "select(): %d\n", errno);
            break;
        } else if (0 == r) {
            /* select() timed out */
            continue;
        } else if (FD_ISSET(client->socket, &ex)) {
            fprintf(stderr, "select(): exception\n");
            break;
        } else if (FD_ISSET(client->socket, &wr)) {
            size_t n = 0;
            while (sbuflen > sent && 0 < (n = (size_t)send(client->socket, &(sbuf[sent]), sbuflen - sent, 0))) {
                sent += n;
            }
            if (-1 == n) {
#ifdef _WIN32
                int wsaerr = WSAGetLastError();
                if (WSAEWOULDBLOCK != wsaerr) {
                    fprintf(stderr, "send(): %d\n", wsaerr);
#else
                if (EAGAIN != errno && EWOULDBLOCK != errno) {
                    fprintf(stderr, "send(): %d\n", errno);
#endif  /* _WIN32 */

                    break;
                }
            }
        } else if (FD_ISSET(client->socket, &rd)) {
            size_t n = 0;
            while (0 < (n = (size_t)recv(client->socket, &(rbuf[received]), rchunk, 0))) {
                received += n;
                if ('\r' == rbuf[received - 2] && '\n' == rbuf[received - 1]) {
                    rbuf = (char *)realloc(rbuf, (received + 1) * sizeof(char));
                    rbuf[received] = '\0';
                    break;
                } else {
                    rbuf = (char *)realloc(rbuf, (received + rchunk) * sizeof(char));
                }
            }
            if (-1 == n) {
#ifdef _WIN32
                int wsaerr = WSAGetLastError();
                if (WSAEWOULDBLOCK != wsaerr) {
                    fprintf(stderr, "recv(): %d\n", wsaerr);
#else
                if (EAGAIN != errno && EWOULDBLOCK != errno) {
                    fprintf(stderr, "recv(): %d\n", errno);
#endif  /* _WIN32 */
                    break;
                }
            } else if (2 <= received && '\r' == rbuf[received - 2] && '\n' == rbuf[received - 1]) {
                if (client->is_verbose) {
                    fprintf(stderr, "%d RECV: %d %s\n", (int)time(NULL), (int)received, rbuf);
                }
                break;
            } else if (0 == received) {
                break;
            }
        }
    }

    if (0 < received) {
        if (NULL == (response = cJSON_Parse(rbuf))) {
            dbc_disconnect(client);
            fprintf(stderr, "Failed parsing API response\n");
            response = cJSON_CreateObject();
        }
    } else {
        dbc_disconnect(client);
        fprintf(stderr, "Connection lost\n");
    }

    free(rbuf);
    return response;
}

/**
 * Make a Death by Captcha API call.
 * Takes the active client, API command name, request arguments (can be NULL).
 * Returns API response on success, or NULL.
 */
cJSON *dbc_call(dbc_client *client, const char *cmd, cJSON *args)
{
    int err = 0x00;
    int attempts = 2;

    cJSON *response = NULL;
    char *sbuf = NULL;

    int is_args_local = 0;
    if (NULL == args) {
        is_args_local = 1;
        args = cJSON_CreateObject();
    }
    cJSON_AddStringToObject(args, "cmd", cmd);
    cJSON_AddStringToObject(args, "version", DBC_API_VERSION);

    sbuf = cJSON_PrintUnformatted(args);
    sbuf = (char *)realloc(sbuf, (strlen(sbuf) + 3) * sizeof(char));
    sbuf = strcat(sbuf, DBC_TERMINATOR);

    while (0 < attempts && NULL == response && 0x00 == err) {
        attempts--;

        if (!dbc_connected(client) && strcmp(cmd, "login")) {
            cJSON *auth = cJSON_CreateObject();
            cJSON_AddStringToObject(auth, "username", client->username);
            cJSON_AddStringToObject(auth, "password", client->password);
            dbc_call(client, "login", auth);
        }

#ifdef _WIN32
        if (WAIT_OBJECT_0 == WaitForSingleObject(client->socket_lock, INFINITE)) {
#else
        if (!sem_wait(&(client->socket_lock))) {
#endif  /* _WIN32 */
            response = dbc_send_and_recv(client, sbuf);
            if (NULL == response) {
                /* Worth retrying */
            } else {
                cJSON *tmp = NULL;
                dbc_update_client(client, response);
                if (NULL != (tmp = cJSON_GetObjectItem(response, "error"))) {
                    char *errstr = tmp->valuestring;
                    if (!strcmp(errstr, "not-logged-in")) {
                        fprintf(stderr, "Access denied, check your credentials.\n");
                        err = 0x01;
                    } else if (!strcmp(errstr, "banned")) {
                        fprintf(stderr, "Access denied, account is suspended.\n");
                        err = 0x02;
                    } else if (!strcmp(errstr, "insufficient-funds")) {
                        fprintf(stderr, "CAPTCHA was rejected due to low balance.\n");
                        err = 0x03;
                    } else if (!strcmp(errstr, "invalid-captcha")) {
                        fprintf(stderr, "CAPTCHA was rejected by the service, check if it's a valid image.\n");
                        err = 0x04;
                    } else if (!strcmp(errstr, "service-overload")) {
                        fprintf(stderr, "CAPTCHA was rejected due to service overload, try again later.\n");
                        err = 0x05;
                    } else {
                        fprintf(stderr, "API server error occured: %s\n", errstr);
                        err = 0xff;
                    }
                    errstr = NULL;
                    tmp = NULL;
                }
            }
#ifdef _WIN32
            ReleaseMutex(client->socket_lock);
#else
            sem_post(&(client->socket_lock));
#endif  /* _WIN32 */
        }
    }

    free(sbuf);

    if (is_args_local) {
        cJSON_Delete(args);
    }

    if (0x00 != err) {
        if (NULL != response) {
            cJSON_Delete(response);
            response = NULL;
        }
    }

    return response;
}


void dbc_close(dbc_client *client)
{
    if (NULL != client) {
        if (NULL != client->username) {
            free(client->username);
            client->username = NULL;
        }
        if (NULL != client->password) {
            free(client->password);
            client->password = NULL;
        }
        if (NULL != client->server_addr) {
            freeaddrinfo(client->server_addr);
            client->server_addr = NULL;
        }
        dbc_disconnect(client);
#ifdef _WIN32
        WSACleanup();
        CloseHandle(client->socket_lock);
#else
        sem_destroy(&(client->socket_lock));
#endif  /* _WIN32 */
    }
}

int dbc_init(dbc_client *client, const char *username, const char *password)
{
#ifdef _WIN32
    SECURITY_ATTRIBUTES lock_sec;
    struct WSAData wsad;
    if (WSAStartup(MAKEWORD(2, 0), &wsad)) {
        fprintf(stderr, "WSAStartup(): %d\n", WSAGetLastError());
        return -1;
    }
#endif  /* _WIN32 */

    memset(client, 0, sizeof(dbc_client));
    if (NULL == username || !strlen(username)) {
        fprintf(stderr, "Username is required\n");
    } else if (NULL == password || !strlen(password)) {
        fprintf(stderr, "Password is required\n");
    } else {
        int err;
        char *port = (char *)calloc(6, sizeof(char));
        struct addrinfo hints;
        memset(&hints, 0, sizeof(struct addrinfo));
        hints.ai_family = AF_UNSPEC;
        hints.ai_socktype = SOCK_STREAM;
        hints.ai_flags = 0;
        hints.ai_protocol = 0;
        client->server_addr = (struct addrinfo *)calloc(1, sizeof(struct addrinfo));
        sprintf(port, "%d", dbc_get_random_port());
        if (0 != (err = getaddrinfo(DBC_HOST, port, &hints, &(client->server_addr)))) {
            fprintf(stderr, "getaddrinfo(): %d %s\n", err, gai_strerror(err));
            freeaddrinfo(client->server_addr);
            client->server_addr = NULL;
        }
        free(port);
        if (NULL != client->server_addr) {
#ifdef _WIN32
            SECURITY_ATTRIBUTES lock_sec;
            lock_sec.nLength = sizeof(SECURITY_ATTRIBUTES);
            lock_sec.lpSecurityDescriptor = NULL;
            lock_sec.bInheritHandle = TRUE;
            if (NULL == (client->socket_lock = CreateMutex(&lock_sec, FALSE, NULL))) {
                fprintf(stderr, "CreateMutex(): %d\n", (int)GetLastError());
#else
            if (sem_init(&(client->socket_lock), 0, 1)) {
                fprintf(stderr, "sem_init(): %d\n", errno);
#endif  /* _WIN32 */
            } else {
#ifdef _WIN32
                client->socket = INVALID_SOCKET;
#else
                client->socket = -1;
#endif  /* _WIN32 */
                client->username = (char *)calloc(strlen(username) + 1, sizeof(char));
                strcpy(client->username, username);
                client->password = (char *)calloc(strlen(password) + 1, sizeof(char));
                strcpy(client->password, password);
                return 0;
            }
        }
    }

#ifdef _WIN32
    WSACleanup();
#endif  /* _WIN32 */
    return -1;
}

double dbc_get_balance(dbc_client *client)
{
    if (NULL == client) {
        return 0.0;
    } else {
        cJSON_Delete((cJSON *)dbc_call(client, "user", NULL));
        return client->balance;
    }
}


void dbc_close_captcha(dbc_captcha *captcha)
{
    if (NULL != captcha) {
        captcha->id = 0;
        captcha->is_correct = 1;
        if (NULL != captcha->text) {
            free(captcha->text);
            captcha->text = NULL;
        }
    }
}

int dbc_init_captcha(dbc_captcha *captcha)
{
    if (NULL != captcha) {
        memset(captcha, 0, sizeof(dbc_captcha));
        dbc_close_captcha(captcha);
        return 0;
    } else {
        return -1;
    }
}

int dbc_get_captcha(dbc_client *client,
                    dbc_captcha *captcha,
                    unsigned int id)
{
    if (NULL != client && NULL != captcha && 0 < id) {
        cJSON *response = NULL;
        cJSON *args = cJSON_CreateObject();
        cJSON_AddNumberToObject(args, "captcha", id);
        response = dbc_call(client, "captcha", args);
        dbc_update_captcha(captcha, response);
        cJSON_Delete(args);
        cJSON_Delete(response);
        if (0 < captcha->id) {
            return 0;
        }
    }
    return -1;
}

int dbc_report(dbc_client *client, dbc_captcha *captcha)
{
    if (NULL != client && NULL != captcha && 0 < captcha->id) {
        cJSON *response = NULL;
        cJSON *args = cJSON_CreateObject();
        cJSON_AddNumberToObject(args, "captcha", captcha->id);
        if (NULL != (response = dbc_call(client, "report", args))) {
            dbc_update_captcha(captcha, response);
            cJSON_Delete(response);
        }
        cJSON_Delete(args);
        if (!captcha->is_correct) {
            return 0;
        }
    }
    return -1;
}


/**
 * Upload a CAPTCHA from buffer.
 * Returns 0 on success, cleans up CAPTCHA instance returns -1 if failed.
 */
int dbc_upload(dbc_client *client,
               dbc_captcha *captcha,
               const char *buf,
               size_t buflen)
{
    dbc_init_captcha(captcha);
    if (NULL != client && NULL != buf && 0 < buflen) {
        cJSON *args = cJSON_CreateObject();
        if (NULL != args) {
            cJSON *response = NULL;
            char *encoded_buf = NULL;
            b64encode(&encoded_buf, (const char *)buf, buflen);
            if (NULL != encoded_buf) {
                cJSON_AddStringToObject(args, "captcha", encoded_buf);
                cJSON_AddNumberToObject(args, "swid", DBC_SOFTWARE_VENDOR);
                response = dbc_call(client, "upload", args);
                dbc_update_captcha(captcha, response);
                cJSON_Delete(response);
                free(encoded_buf);
                encoded_buf = NULL;
            }
            cJSON_Delete(args);
        }
        if (0 < captcha->id) {
            return 0;
        }
    }
    dbc_close_captcha(captcha);
    return -1;
}

/**
 * Upload a CAPTCHA from file stream.  See dbc_upload() for details.
 */
int dbc_upload_file(dbc_client *client,
                    dbc_captcha *captcha,
                    FILE *f)
{
    int result = -1;
    if (NULL != client && NULL != f) {
        char *buf = NULL;
        size_t buflen = dbc_load_file(f, &buf);
        if (0 < buflen) {
            result = dbc_upload(client, captcha, buf, buflen);
            free(buf);
            buf = NULL;
        }
    }
    return result;
}


int dbc_decode(dbc_client *client,
               dbc_captcha *captcha,
               const char *buf,
               size_t buflen,
               unsigned int timeout)
{
    int deadline = time(NULL) + (0 < timeout ? timeout : DBC_TIMEOUT);
    if (!dbc_upload(client, captcha, buf, buflen)) {
        while (deadline > time(NULL) && NULL == captcha->text) {
#ifdef _WIN32
            Sleep(DBC_INTERVAL * 1000);
#else
            sleep(DBC_INTERVAL);
#endif  /* _WIN32 */
            if (dbc_get_captcha(client, captcha, captcha->id)) {
                break;
            }
        }
        if (NULL == captcha->text) {
            dbc_close_captcha(captcha);
        } else if (0 == captcha->is_correct) {
            dbc_close_captcha(captcha);
        }
    }
    return NULL != captcha->text ? 0 : -1;
}

int dbc_decode_file(dbc_client *client,
                    dbc_captcha *captcha,
                    FILE *f,
                    unsigned int timeout)
{
    int result = -1;
    char *buf = NULL;
    size_t buflen = dbc_load_file(f, &buf);
    result = dbc_decode(client, captcha, buf, buflen, timeout);
    if (NULL != buf) {
        free(buf);
    }
    return result;
}
