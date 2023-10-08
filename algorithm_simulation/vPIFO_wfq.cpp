// version 6: use PIFO WFQ in root node
// delete the lock
// add anti-starvation mechanism
// change the output information

# include <bits/stdc++.h>

using namespace std;

// L is the max length of packet
const int L = 30;
// M is the number of users, but user 0 is root
const int M = 10;
// N is the number of RPUs, also the number of Task Lists
const int N = 5;
// Each user sends a Push task with a probability of P / M per cycle
const int P = 1; 
// S is the threshold that triggers the anti-starvation mechanism
const int S = 10;
// T is the cycle numbers
const int T = 300;
// In BMW Tree, min = inf means the node is empty
const int inf = 1e9 + 7;

enum Type {
    Push,
    Pop,
    WriteBack,
    Locked,
    Empty
};

struct Task {
    enum Type type;
    // for real queue, val is packet size; for root queue, val is user id
    int root, TTL, rank, val;
    Task () {
        TTL = 0;
        type = Empty;
    }
    Task (enum Type t, int r, int ttl) {
        type = t;
        root = r;
        TTL = ttl;
    }
} RPU[N];

struct Tree {
    pair<double, int> min[2];
    double num[2];
    int son[2];
    Tree() {
        min[0].first = min[1].first = inf;
        num[0] = num[1] = 0;
        son[0] = son[1] = 0;
    }
} node[M<<N];

// record the root node of BMW trees
int tree[M], tot;

int get_son (int root, int d) {
    if (node[root].son[d] != 0)
        return node[root].son[d];
    tot++;
    node[root].son[d] = tot;
    return tot;
}

void push (int root, pair<double, int> val) {
    // try to insert x in this node
    if (node[root].min[0].first == inf) {
        node[root].min[0] = val;
        return;
    }
    if (node[root].min[1].first == inf) {
        node[root].min[1] = val;
        return;
    }

    // insert x in one of the son
    int go_down = 0;
    if (node[root].num[0] > node[root].num[1])
        go_down = 1;
    if (val < node[root].min[go_down]) {
        push(get_son(root, go_down), node[root].min[go_down]);
        node[root].min[go_down] = val;
    }
    else
        push(get_son(root, go_down), val);
    node[root].num[go_down]++;
}

pair<double, int> pop (int root) {
    pair<double, int> ret;
    int go_down = 0;
    if (node[root].min[0] > node[root].min[1])
        go_down = 1;
    ret = node[root].min[go_down];
    node[root].min[go_down].first = inf;
    if (node[root].son[go_down] != 0) {
        node[root].min[go_down] = pop(node[root].son[go_down]);
        node[root].num[go_down]--;
    }
    return ret;
}

void tree_print (int fa, int root, int dep) {
    printf("node %d is son of %d, dep = %d\n", root, fa, dep);
    printf("min0 = %.2lf, min1 = %.2lf\n", node[root].min[0].first, node[root].min[1].first);
    printf("num0 = %d, num1 = %d\n", node[root].num[0], node[root].num[1]);
    if (node[root].son[0])
        tree_print(root, node[root].son[0], dep + 1);
    if (node[root].son[1])
        tree_print(root, node[root].son[1], dep + 1);
}

int task_num[M], use_num;
double Q;
int wait_time[N], finish_time[M], virtual_time;
int starve_count, hungry_count, hungry_delay, send_count[N];
int push_num[M], pop_num[M], push_sum, pop_sum;

queue<Task> task_list[N];

void push_list (int i, Task t) {
    if (task_list[i].empty())
        wait_time[i] = 0;
    task_list[i].push(t);
}

void pop_list (int i) {
    task_list[i].pop();
    if (wait_time[i] > S) {
        hungry_count++;
        hungry_delay += wait_time[i] - S;
    }
    if (task_list[i].empty())
        wait_time[i] = -inf;
    else
        wait_time[i] = 0;
}


int main() {

    // initialize the roots of the trees
    for (int i = 0; i < M; ++i)
        tree[i] = ++tot;
    // when the queue is empty, don't count wait_time
    memset(wait_time, -0x3f, sizeof(wait_time));
    

    Task t;
    pair<double, int> pa;

    printf("N = %d, M = %d\n", N, M);

    for (int cycle = 0; cycle < T; ++cycle) {
        t = (Task){Push, 0, N};

        // insert push task
        // Attention: 0 is the root queue and it don't send push task proactively
        for (int i = 1, j; i < M; ++i) {
            j = rand() % M;
            if (j <= P) {
                // pifo i send a push task and the packet size is val
                t.root = i;
                t.rank = rand() % inf;
                t.val = rand() % L;
                push_list(i % N, t);
                task_num[i]++;

                // pifo 0 send push i
                t.root = 0;
                // If the rates for all users are equal, packet size can be use as process time
                finish_time[i] = max(finish_time[i], virtual_time) + t.val;
                // WFQ use finish time as rank
                t.rank = finish_time[i];
                t.val = i;
                push_list(0, t);
                task_num[0]++;
            }
        }
        

        // insert pop root task every two cycle
        if (T % 2 == 0 && task_num[0] > 0) {
            t = (Task){Pop, 0, N};
            push_list(0, t);
            task_num[0]--;
        }

        // statistics before updating status
        for (int i = 0; i < N; ++i) {
            // the RPU is running
            if (RPU[i].type == Push || RPU[i].type == Pop || RPU[i].type == WriteBack)
                use_num++;
            // after a root pop, now we know which tree to pop
            if (RPU[i].TTL == N && RPU[i].type == Pop) {
                int ans = pop(tree[RPU[i].root]).second;
                if (RPU[i].root == 0) {
                    t = (Task){Pop, ans, N};
                    // printf("log: add pop task %d\n", ans);
                    push_list(ans % N, t);
                    task_num[ans]--;
                }
                else 
                    virtual_time += ans;
            }
            if (RPU[i].TTL == 1 && RPU[i].root != 0) {
                if (RPU[i].type == Push) {
                    push_sum++;
                    push_num[RPU[i].root]++;
                }
                else if (RPU[i].type == Pop) {
                    pop_sum++;
                    pop_num[RPU[i].root]++;
                }
            }
        }

        // pass down the existing task
        Task nt[2]; // scrolling array used to pass the task
        nt[1] = RPU[N - 1];
        nt[1].TTL--;
        for (int i = 0, j; i < N; ++i) {
            j = i & 1;
            // pass task in RPUi to the next RPU
            nt[j] = RPU[i];
            nt[j].TTL--;
            // after Pop, set a WriteBack, the TTL remains the same
            if (RPU[i].type == Pop) {
                RPU[i].type = WriteBack;
            }
            // inherit task from the last RPU
            else if (nt[j ^ 1].TTL > 0) {
                RPU[i] = nt[j ^ 1];
            }
            // set the RPU as Empty
            else {
                RPU[i].type = Empty;
                RPU[i].TTL = 0;
            }
        }

        // anti-starvation mechanism
        for (int i = 0; i < N; ++i) {
            wait_time[i]++;
            if (wait_time[i] > S) {

            }
        }

        // send new task
        for (int i = 0, j; i < N; ++i) {
            if (RPU[i].type == Empty) {
                if (!task_list[i].empty()) {
                    Task t = task_list[i].front();
                    send_count[i]++;
                    if (t.type == Push) {
                        RPU[i] = t;
                        pa.first = t.rank;
                        pa.second = t.val;
                        push(tree[t.root], pa);
                        // printf("log: push val %d of tree %d in RPU %d\n", t.val, t.root, i);
                        pop_list(i);
                    }
                    else {
                        j = (i - 1 + N) % N;
                        if (RPU[j].TTL <= 1) {
                            RPU[i] = t;
                            pop_list(i);
                            // printf("log: pop tree %d in RPU %d\n", t.root, i);
                            // The last RPU should be locked
                            if (RPU[j].type == Empty)
                                RPU[j].type = Locked;
                            RPU[j].TTL = 1;
                        }
                    }
                }
            }
        }

        /*
        printf("Cycle %d\n", T);
        printf("push sum: %d, pop sum: %d\n", push_sum, pop_sum);
        for (int i = 1; i < M; ++i)
            printf("user %d  push num: %d, pop num: %d\n", i, push_num[i], pop_num[i]);
        */
        if (hungry_count > 0) {
            printf("hungry time: %d, starve time: %d\n, ", hungry_count, starve_count);
            printf("average hungry delay: %.2lf\n", 1.0 * hungry_delay / hungry_count);
        }
    }

    /*
    for (int i = 0; i < M; ++i) {
        printf("\nlog: Tree %d\n", i);
        tree_print(0, tree[i], 1);
    }
    */

    for (int i = 0; i < N; ++i)
        printf("throughput of task list %d : %.2lf\n", i, 1.0 * send_count[i] / T);

    Q = ((double)use_num) / ((double)(N * T));
    printf("use_num = %d, T = %d, Q = %.4lf\n", use_num, T, Q);

    return 0;
}