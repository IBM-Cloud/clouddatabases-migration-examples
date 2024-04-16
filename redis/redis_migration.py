"""
Forked from https://gist.github.com/kitwalker12/517d99c3835975ad4d1718d28a63553e
Modified to work with IBM Cloud Databases for Redis
Copies all keys from the source Redis host to the destination Redis host.
Useful to migrate Redis instances where commands like SLAVEOF and MIGRATE are
restricted (e.g. IBM Cloud Databases for Redis).
The script scans through the keyspace of the given database number and uses
a pipeline of DUMP and RESTORE commands to migrate the keys.
Requires Redis 2.8.0 or higher.
Python requirements:
click
progressbar
redis
Sample usage on the command line:
python pymigration.py <srchost name> <src password or ""> <srcport> <dsthost Databases for Redis host> <dsthostauth password> <dsthostport port> <dsthostcacert location of CA cert> 
If you're migrating to Databases for Redis, use the --ssldst flag.
If you're source database uses SSL/TLS, then also use the --sslsrc flag.
You can specify the Redis database to copy from/into using the --db flag and flush the destination database using the --flush flag.
If the destination Redis version is less than 6, dsthostauth should be the password. If 6 or greater it should be username:password
"""

import click
from progressbar import ProgressBar
from progressbar.widgets import Percentage, Bar, ETA
import redis
from redis.exceptions import ResponseError

@click.command()
@click.argument('srchost')
@click.argument('srchostauth')
@click.argument('srchostport')
@click.argument('dsthost')
@click.argument('dsthostauth')
@click.argument('dsthostport')
@click.argument("dsthostcacert")
@click.option('--sslsrc',default=False, is_flag=True, help='Set TLS/SSL flag for source')
@click.option('--ssldst',default=False, is_flag=True, help='Set TLS/SSL flag for destination')
@click.option('--db', default=0, help='Redis db number, default 0')
@click.option('--flush', default=False, is_flag=True, help='Delete all keys from destination before migrating')
@click.option('--dryrun', default=False, is_flag=True, help='Execute test run of flush (if enabled) and migration')

def migrate(srchost, srchostauth, srchostport, dsthost, dsthostauth, dsthostport, dsthostcacert, sslsrc, ssldst, db, flush, dryrun):
    if srchost == dsthost:
        print('Source and destination must be different.')
        return

    if ":" in srchostauth:
      username, password = srchostauth.split(":")
      source = redis.Redis(host=srchost, port=int(srchostport), db=db, username=username, password=password, ssl=sslsrc, ssl_cert_reqs=None)
    else:
      source = redis.Redis(host=srchost, port=int(srchostport), db=db, password=srchostauth, ssl=sslsrc, ssl_cert_reqs=None)

    if ":" in dsthostauth:
      username, password = dsthostauth.split(":")
      dest = redis.Redis(host=dsthost, port=int(dsthostport), db=db, username=username, password=password, ssl=ssldst, ssl_ca_certs=dsthostcacert)
    else:
      dest = redis.Redis(host=dsthost, port=int(dsthostport), db=db, password=dsthostauth, ssl=ssldst, ssl_ca_certs=dsthostcacert)

    if flush and not dryrun:
        dest.flushdb()

    size = source.dbsize()

    if size == 0:
        print('No keys found.')
        return

    progress_widgets = ['%d keys: ' % size, Percentage(), ' ', Bar(), ' ', ETA()]
    pbar = ProgressBar(widgets=progress_widgets, maxval=size).start()

    COUNT = 2000 # scan size

    cnt = 0
    non_existing = 0
    already_existing = 0
    cursor = 0

    while True:
        cursor, keys = source.scan(cursor, count=COUNT)
        pipeline = source.pipeline()

        for key in keys:
            pipeline.pttl(key)
            pipeline.dump(key)

        result = pipeline.execute()
        pipeline = dest.pipeline()

        for key, ttl, data in zip(keys, result[::2], result[1::2]):
            # Sets TTL to 0 according to the library requirements. Since TTL in Redis will give -1 if key exists but no TTL is assigned
            if ttl == -1:
                ttl = 0
            if data != None:
                if dryrun:
                    # Execute generic operation to determine whether key exists. This is
                    # used in place of 'restore' to help generate the 'already_existing'
                    # summary statistic.
                    pipeline.type(key)
                else:
                    pipeline.restore(key, ttl, data)
            else:
                non_existing += 1

        results = pipeline.execute(False)

        for key, result in zip(keys, results):
            if dryrun:
                # If 'type' returned something other than 'none', we know the key exists.
                # If 'flush' is enabled, pretend the key doesn't exist to avoid a non-zero
                # 'already_existing' count on dryrun flush.
                if not flush and result != b'none':
                    already_existing += 1
            elif result != b'OK':
                e = result
                if hasattr(e, 'args') and (e.args[0] == 'BUSYKEY Target key name already exists.' or e.args[0] == 'Target key name is busy.'):
                    already_existing += 1
                else:
                    print('Key failed:', key, 'data', result)
                    raise e

        if cursor == 0:
            break

        cnt += len(keys)
        pbar.update(min(size, cnt))

    pbar.finish()
    print('Keys disappeared on source during scan:', non_existing)
    print('Keys already existing on destination:', already_existing)

if __name__ == '__main__':
    migrate()
